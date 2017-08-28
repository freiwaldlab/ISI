function runExpt
global GUIhandles Mstate
global trialno trialInfo
global pathBase pathData
global syncInfo analogIN analogINdata daqOUT2p
global prefixDate prefixTrial

modID = getmoduleID;
if Mstate.running
    nt = getnotrials;
end

% Determine what to run from GUI toggles
twoPbit = get(GUIhandles.main.twophotonflag, 'value');
ISIbit = get(GUIhandles.main.intrinsicflag, 'value');

if Mstate.running && (trialno <= nt)
    prefixTrial = sprintf('t%0*.0f', numel(num2str(nt)), trialno);
    set(GUIhandles.main.showTrial, 'string', ...
        ['Trial ' prefixTrial ' of ' ...
        sprintf('t%0*.0f', numel(num2str(nt)), nt)]);
    drawnow

    [c,r] = getcondrep(trialno);
    
    %if twoPbit
    %    update2Ptrial(trialno)
    %end

    buildStimulus(c, trialno)
    waitforDisplayResp
    
    if ISIbit
        % Each ImageBlock trial can have different total durations 
        % and acquired frames
        P = getParamStruct;
        if strcmpi(modID, 'IB')
            tag_time = str2double(get(findobj('tag', 'timetxt'), 'string'));
            total_time = P.predelay + P.postdelay + tag_time;
        else
            total_time = P.predelay + P.postdelay + P.stim_time;
        end
        sendtoImager(sprintf(['I %2.3f' 13], total_time))
        
        pathData = fullfile(pathBase, [prefixDate '_' prefixTrial '_data']);
        if ~exist(pathData, 'dir')
            mkdir(pathData);
            disp([mfilename ': Data path did not exist. ' ...
                'Created [' pathData '].']);
        end
        fileLog = fullfile(pathBase, [prefixDate '_' prefixTrial '.log']);
        fid1 = fopen(fileLog, 'w');
        lhIn = addlistener(analogIN, ...
            'DataAvailable', @(src, event)logData(src, event, fid1));
        analogIN.startBackground;
        disp([mfilename ': Log file opened [' fileLog '].']);
    end
    
    pause(0.25)
    startStimulus

    if twoPbit
        high = 1;
        low = 0;
        outputSingleScan(daqOUT2p, high);
        ttlTmsec = 50 / 1000;
        tic;
        while toc < ttlTmsec
        end
        outputSingleScan(daqOUT2p, low);
        clear high low
    end
    if ISIbit
        sendtoImager(sprintf(['S %d' 13], trialno))
    end
    
    if strcmpi(getmoduleID, 'IB')
        if ~isempty(trialInfo)
            saveTrialInfo(trialInfo)
        else
            error([mfilename ': Failed to retrieve ImageBlock trialInfo.']);
        end
    end
    
    if ISIbit
        % For some reason, pausing is necessary here for log file to save
        % properly before listener and file closing
        pause(0.25)
        analogIN.stop;
        delete(lhIn);
        fclose(fid1);
        disp([mfilename ': Reading log file (' fileLog ').']);
        fid2 = fopen(fileLog, 'r');
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
        Fs = analogIN.Rate;  % 1000;  % sampling frequency in Hz; set in configSyncInput
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
        saveSyncInfo(syncInfo)
        
        %[looperInfo.conds{c}.repeats{r}.dispSyncs ...
        %    looperInfo.conds{c}.repeats{r}.acqSyncs ...
        %    looperInfo.conds{c}.repeats{r}.dSyncswave] = getSyncTimes;
        
        %Compute F1
        onlineAnalysis(c, r, syncInfo)
    end
    
    trialno = trialno + 1;
    if ISIbit
        runExpt
    end
else
    Mstate.running = 0;
    set(GUIhandles.main.runbutton, 'string', 'Run')
    
    if get(GUIhandles.main.intrinsicflag, 'value')
        saveOnlineAnalysis
    end
end