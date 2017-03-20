function GrabSaveLoop(fname)
    global imagerhandles frameN Tens trigSeq
    global daqOUTtrig daqOUTIOI
    h = imagerhandles;
    
    % Set whether debugging output should be displayed
    debugToggle = 0;
    % Set whether or not data should be saved (useful during debugging)
    saveToggle = 1;
    
    % Fetch the total set acquisition time
    %%% TODO XXX *** automatically infer this this from stimulus parameters?
    total_time = str2double(get(findobj('tag', 'timetxt'), 'string'));

    % If in debug mode, display current logging mode setting
    if debugToggle
        disp(['GrabSaveLoop: Camera logging mode set to ' ...
            h.video.LoggingMode])
    end

    %%% TODO XXX *** 2p testing
    % global daqOUT2p
    % outputSingleScan(daqOUT2p, 1);
    % ttltime = 10/1000; %time in ms
    % tic;
    % while toc < ttltime
    % end
    % outputSingleScan(daqOUT2p, 0);
    
    % Start camera (frames will not be acquired until separately triggered)
    queueOutputData(daqOUTtrig, trigSeq);
    % Send pulse to timing DAQ indicate that acquisition is beginning
    outputSingleScan(daqOUTIOI, 1);
    % Trigger acquisition via hardware (TTL to camera)
    startBackground(daqOUTtrig); % trigger sequence in preallocateTensor
    tic;
    frameNleft = frameN;
    frameNrecd = 0;
    frameNbase = h.video.FramesAcquired;
    timelastframe = now;
    maxwait = 10;
    fprintf('GrabSaveLoop: Acquiring %d frames...\n', frameNleft)
    while (frameNleft > 0) && (((10^5)*(now - timelastframe)) <= maxwait)
        frameNacqd = h.video.FramesAcquired - frameNbase;
        frameNaval = h.video.FramesAvailable;
        if frameNaval == 0
            continue
        end
        frameR = (frameNrecd + 1):(frameNrecd + frameNaval);
        frameRnum = length(frameR);
        if debugToggle
            disp(['GrabSaveLoop DEBUG: ' num2str(frameNacqd) ...
                ' frames acquired. ' num2str(frameNaval) ...
                ' remaining on camera.'])
        end
        fprintf('.')
        % Get next frame data set from camera
        Tens(:,:,frameR) = permute(squeeze(getdata(h.video, frameRnum)), ...
            [2 1 3]);
        timelastframe = now;
        % Save frames to disk
        if saveToggle
            tsave = tic;
            % Save the buffer to disk as individual frames
            for n = 1:frameRnum
                fn = frameR(n);
                im = Tens(:,:,fn);
                fnamedum = [fname '_' 'f' num2str(fn)];
                save(fnamedum, 'im', '-v6');
            end
            totalsaveT = toc(tsave);
            clear n im imlast tsave
            if debugToggle && (frameRnum > 0)
                disp(['GrabSaveLoop DEBUG: Save time for recent '...
                    'fetched frames was ' num2str(totalsaveT) ' sec.'])
                disp(['GrabSaveLoop DEBUG:           per frame ' ...
                    num2str(totalsaveT / frameRnum) ' sec.'])
            end
        end
        % Track frames
        frameNleft = frameNleft - frameRnum;
        frameNrecd = frameNrecd + frameRnum;
    end
    fprintf(' done.\n')
    if (frameNleft > 0) && ((10^5)*(now - timelastframe) > maxwait)
        disp(['GrabSaveLoop WARNING: Stopped waiting for frames from ' ...
            ' camera after ' num2str((10^5)*(now - timelastframe)) ...
            ' sec idle.'])
    end
    frameNacqd = h.video.FramesAcquired - frameNbase;
    if frameNrecd < frameN
        disp(['GrabSaveLoop WARNING: Received fewer (' ...
            num2str(frameNrecd) ') frames than expected (' ...
            num2str(frameN) ').'])
    end
    totalT = toc;
    frameTsec = totalT / frameNrecd;
    disp(['GrabSaveLoop: Total frames acquired ' ...
        num2str(frameNacqd) ', ' num2str(frameN) ' expected.'])
    disp(['GrabSaveLoop: Total acquisition and pull time was ' ...
        num2str(totalT) ' sec, ' num2str(total_time) ...
        ' sec expected.'])
    disp(['GrabSaveLoop: Acquisition and pull time per frame ' ...
        num2str(frameTsec) ' sec, ' num2str(total_time / frameN) ...
        ' sec expected.'])
    % Send pulse to timing DAQ to indicate that acquisition is complete
    outputSingleScan(daqOUTIOI, 0);

    imagerhandles = h;