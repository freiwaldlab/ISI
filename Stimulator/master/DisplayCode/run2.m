function run2
global GUIhandles Mstate trialno syncInfo trialInfo analogIN analogINdata
global DataPath LogFile

mod = getmoduleID;

%otherwise 'getnotrials' won't be defined for play sample
if Mstate.running
    nt = getnotrials;
end

% Determine what to run from GUI toggles
ScanImageBit = get(GUIhandles.main.twophotonflag, 'value');
ISIbit = get(GUIhandles.main.intrinsicflag, 'value');

%'trialno<nt' may be redundant.
if Mstate.running && (trialno <= nt)
    set(GUIhandles.main.showTrial, 'string', ...
        ['Trial ' num2str(trialno) ' of ' num2str(nt)] );
    drawnow

    %get cond and rep for this trialno
    [c, r] = getcondrep(trialno);

    %if ISIbit
    %    LogFile = [DataPath filesep 'run_log_' ...
    %        sprintf('%03d', trialno) '.bin'];
    %    fid1 = fopen(LogFile, 'w');
    %    lhIn = addlistener(analogIN, ...
    %        'DataAvailable', @(src, event)logData(src, event, fid1));
    %    analogIN.startBackground;
    %    disp(['run2: Log file opened (' LogFile ').'])
    %end
    
    %%%Update ScanImage with Trial/Cond/Rep
    %This gets sent before trial starts
    if ScanImageBit
        updateACQtrial(trialno)
    end

    %%%Organization of commands is important for timing in this part of loop
    %Tell stimulus to buffer the images (also controls shutter)
    buildStimulus(c, trialno)
    %Wait for serial port to respond from display
    waitforDisplayResp
    %Tell Display to show its buffered images. 
    %TTL from stimulus computer "feeds back" to trigger 2ph acquisition
    
    if ISIbit
        % moved here from MainWindow so that each trial can have
        % different total durations and acquired frames
        P = getParamStruct;
        if strcmpi(mod, 'IB')
            tag_time = str2double(get(findobj('tag', 'timetxt'), 'string'));
            total_time = P.predelay + P.postdelay + tag_time;
        else
            total_time = P.predelay + P.postdelay + P.stim_time;
        end
        sendtoImager(sprintf(['I %2.3f' 13], total_time))
        
        LogFile = [DataPath filesep 'run_log_' ...
            sprintf('%03d', trialno) '.bin'];
        fid1 = fopen(LogFile, 'w');
        lhIn = addlistener(analogIN, ...
            'DataAvailable', @(src, event)logData(src, event, fid1));
        analogIN.startBackground;
        disp(['run2: Log file opened (' LogFile ').'])
    end
    
    startStimulus      
    
    %In 2ph mode, we don't want anything significant to happen after startStimulus, so that
    %scanimage will be ready to accept TTL
    
    if ISIbit
        %Matlab now enters the frame grabbing loop
        sendtoImager(sprintf(['S %d' 13], trialno - 1))
        %%%Timing is not crucial for this last portion of the loop 
        %(both display and frame grabber/saving is inactive)...
        
        if strcmpi(getmoduleID, 'IB')
            if ~isempty(trialInfo)
                saveTrialInfo(trialInfo)
            else
                disp('run2 ERROR: Failed to retrieve ImageBlock trialInfo.')
            end
        end
        
        % For some reason, pausing is necessary here for log file to save
        % properly before listener and file closing
        pause(0.25)
        analogIN.stop;
        delete(lhIn);
        fclose(fid1);
        disp(['run2: Reading log file (' LogFile ').']);
        fid2 = fopen(LogFile, 'r');
        % analogINdata is a 6 x samples matrix where...
        %   (1,:) is the time each sample is taken from start
        %   (2,:) is the voltage on analog input 0: photodiode from display
        %   (3,:) is the voltage on analog input 1: strobe from camera
        %   (4,:) is the voltage on analog input 2: trigger copy
        %   (5,:) is the voltage on analog input 3: audio copy
        %   (6,:) is the voltage on analog input 4: start/stop ttl copy
        [analogINdata,~] = fread(fid2, [6,inf], 'double');
        fclose(fid2);
        
        samples = length(analogINdata);
        timevals = analogINdata(1,:)';
        Fs = analogIN.Rate;  % 2000;  % sampling frequency in Hz; set in configSyncInput
        stimsync = analogINdata(2,:)';

        % Normalize photodiode signal
        high = max(stimsync);
        low = median(stimsync);  % median to avoid negative transients
        thresh = (high + low) / 2;
        stimsync = sign(stimsync - thresh);
        stimsync(stimsync == 0) = 1;
        stimsync = (stimsync - min(stimsync)) / ...
            (max(stimsync) - min(stimsync));
        
        % Filter out down states caused by monitor refresh
        %Mstate.refresh_rate
        delta = 120 / Fs;  % window of one monitor refresh period
        hightimes = timevals(stimsync == 1);
        stimsq = stimsync;
        highidx = find(stimsq == 1);
        for idx = 1:length(highidx)-1
            if (hightimes(idx+1) - hightimes(idx)) <= delta
                stimsq(highidx(idx):highidx(idx+1)) = 1;
            end
        end
        
        figure; clf
        hold on
        %plot(timevals, analogINdata(1,1:1:samples)', 'k') % time
        plot(timevals, stimsq, 'r') % photodiode filtered
        plot(timevals, analogINdata(2,:)', 'm') % photodiode raw
        plot(timevals, analogINdata(6,:)', 'k') % start/stop ttl camera
        plot(timevals, analogINdata(4,:)', 'b') % trigger
        plot(timevals, analogINdata(3,:)', ':b') % strobe
        plot(timevals, analogINdata(5,:)', 'g') % audio
        %plot(timevals, high * ones(samples, 1), 'k') % photodiode high
        %plot(timevals, thresh * ones(samples, 1), 'y') % photodiode thresh
        %plot(timevals, low * ones(samples, 1), 'k') % photodiode low
        hold off
        legend('StimFilt', 'StimRaw', 'ISIttl', ...
            'CamTrig', 'CamStrb', 'Audio');
        xlim([0 timevals(samples)])
        xlabel('Time')
        ylabel('Voltage')

        [syncInfo.dispSyncs, syncInfo.acqSyncs, syncInfo.dSyncswave] = ...
            getSyncTimes;
        syncInfo.dSyncswave = [];
        % Append to .analyzer file
        saveSyncInfo(syncInfo)
        
        %[looperInfo.conds{c}.repeats{r}.dispSyncs looperInfo.conds{c}.repeats{r}.acqSyncs looperInfo.conds{c}.repeats{r}.dSyncswave] = getSyncTimes;
        
        %Compute F1
        onlineAnalysis(c, r, syncInfo)
    end
    
    trialno = trialno + 1;
    
    %This would otherwise get called by Displaycb 
    if ISIbit
        %Nothing should happen after this
        run2
    end
else
    %Before, I had this in the 'mainwindow callback routine, which messed
    %things up on occasion.
    %This is executed at the end of experiment and when abort button is hit
    if get(GUIhandles.main.twophotonflag,'value')
        Stimulus_localCallback('abort'); %Tell ScanImage to hit 'abort' button
    end
    
    %set(GUIhandles.param.playSample,'enable','off')
    
    Mstate.running = 0;
    set(GUIhandles.main.runbutton, 'string', 'Run')
    
    if get(GUIhandles.main.intrinsicflag, 'value')
        %set(GUIhandles.param.playSample,'enable','off')
        saveOnlineAnalysis
    end
end