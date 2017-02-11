function run2
global GUIhandles Mstate trialno syncInfo analogIN analogINdata
global DataPath LogFile

LogFile = [DataPath filesep 'run_log.bin'];

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

    if ISIbit
        fid1 = fopen(LogFile, 'w');
        lh = addlistener(analogIN, ...
            'DataAvailable', @(src, event)logData(src, event, fid1));
        analogIN.startBackground;
        disp(['run2: Log file opened (' LogFile ').'])
    end
    
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
    startStimulus      
    
    %In 2ph mode, we don't want anything significant to happen after startStimulus, so that
    %scanimage will be ready to accept TTL
    
    if ISIbit
        %Matlab now enters the frame grabbing loop
        sendtoImager(sprintf(['S %d' 13], trialno - 1))
        %%%Timing is not crucial for this last portion of the loop 
        %(both display and frame grabber/saving is inactive)...
        
        % For some reason, pausing is necessary here for log file to save
        % properly before listener and file closing
        pause(0.25)
        analogIN.stop;
        delete(lh);
        fclose(fid1);
        disp(['run2: Reading log file (' LogFile ').']);
        fid2 = fopen(LogFile, 'r');
        % analogINdata is a 3 x samples matrix where...
        %   (1,:) is the time each sample is taken from start
        %   (2,:) is the voltage on analog input 0: photodiode from display
        %   (3,:) is the voltage on analog input 1: TTL from camera
        [analogINdata,~] = fread(fid2, [3,inf], 'double');
        fclose(fid2);
        
        samples = length(analogINdata);
        timevals = analogINdata(1,:)';
        %%% DEBUG XXX ***
        figure; clf
        hold on
        %plot(timevals, analogINdata(1,1:1:samples)', 'k') % time
        plot(timevals, analogINdata(2,1:1:samples)', 'r') % photodiode
        plot(timevals, analogINdata(3,1:1:samples)', 'b') % camera
        hold off
        %axis equal
        %legend('Time', 'Stimulus', 'Camera')
        legend('Stimulus', 'Camera')
        xlim([0 timevals(samples)])
        xlabel('Time')
        ylabel('Voltage')
        
        %figure; clf
        %hold on
        % %plot(analogINdata(1,1:1:samples)', 'k') % time
        %plot(analogINdata(2,1:1:samples)', 'r') % photodiode
        %plot(analogINdata(3,1:1:samples)', 'b') % camera
        %hold off
        % %axis equal
        % %legend('Time', 'Stimulus', 'Camera')
        %legend('Stimulus', 'Camera')
        %xlim([0 samples])
        %xlabel('Samples')
        %ylabel('Voltage')

        [syncInfo.dispSyncs, syncInfo.acqSyncs, syncInfo.dSyncswave] = ...
            getSyncTimes;   
        %Just empty it for now
        syncInfo.dSyncswave = [];
        %append .analyzer file
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
