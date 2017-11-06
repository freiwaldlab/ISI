function GrabSaveLoop(pathData, prefixTrial)
    global imagerhandles frameN Tens FrameTimes
    global daqOUTtrig daqOUTIOI
    h = imagerhandles;
    
    % Set whether debugging output should be displayed
    debugToggle = 0;
    % Set whether or not data should be saved (useful during debugging)
    saveToggle = 1;
    
    % Fetch the total set acquisition time
    total_time = str2double(get(findobj('tag', 'timetxt'), 'string'));

    % If in debug mode, display current logging mode setting
    if debugToggle
        disp([mfilename ': Camera logging mode set to ' ...
            h.video.LoggingMode]);
    end
    
    % Start camera (frames will not be acquired until separately triggered)
    % Send pulse to timing DAQ indicate that acquisition is beginning
    outputSingleScan(daqOUTIOI, 1);
    % Trigger acquisition via hardware (TTL to camera)
    startBackground(daqOUTtrig);  % sequence from preallocateTensor
    tic;
    frameNleft = frameN;
    frameNrecd = 0;
    frameNbase = h.video.FramesAcquired;
    timelastframe = now;
    maxwait = 10;
    fprintf('%s: Acquiring %d frames...\n', mfilename, frameNleft)
    while (frameNleft > 0) && (((10^5)*(now - timelastframe)) <= maxwait)
        frameNacqd = h.video.FramesAcquired - frameNbase;
        frameNaval = h.video.FramesAvailable;
        if frameNaval == 0
            continue
        end
        frameR = (frameNrecd + 1):(frameNrecd + frameNaval);
        frameRnum = length(frameR);
        if debugToggle
            disp([mfilename ' DEBUG: ' num2str(frameNacqd) ...
                ' frames acquired. ' num2str(frameNaval) ...
                ' remaining on camera.']);
        end
        fprintf('.')
        % Get next frame data set from camera
        %Tens(:,:,frameR) = fliplr(permute(squeeze(getdata(h.video, frameRnum)), ...
        %    [2 1 3]));
        %Tens(:,:,frameR) = flipud(permute(squeeze(getdata(h.video, frameRnum)), ...
        %    [2 1 3]));
        [frames, framesTrel, ~] = getdata(h.video, frameRnum);
        Tens(:,:,frameR) = rot90(permute(squeeze(frames), [2 1 3]), 2);
        FrameTimes(frameR) = framesTrel;
        timelastframe = now;
        % Save frames to disk
        if saveToggle
            tsave = tic;
            % Save the buffer to disk as individual frames
            for n = 1:frameRnum
                fn = frameR(n);
                im = Tens(:,:,fn);
                tm = FrameTimes(fn);
                save_path = fullfile(pathData, [prefixTrial '_f' ...
                    sprintf('%0*.0f', numel(num2str(frameN)), fn)]);
                %save(save_path, 'im', '-v6');
                save(save_path, 'im', 'tm', '-v6');
            end
            totalsaveT = toc(tsave);
            clear n im tm tsave
            if debugToggle && (frameRnum > 0)
                disp([mfilename ' DEBUG: Save time for recent '...
                    'fetched frames was ' num2str(totalsaveT) ' sec.']);
                disp([mfilename ' DEBUG:           per frame ' ...
                    num2str(totalsaveT / frameRnum) ' sec.']);
            end
        end
        % Track frames
        frameNleft = frameNleft - frameRnum;
        frameNrecd = frameNrecd + frameRnum;
    end
    fprintf(' done.\n')
    if (frameNleft > 0) && ((10^5) * (now - timelastframe) > maxwait)
        warning([mfilename ': Stopped waiting for frames from ' ...
            ' camera after ' num2str((10^5)*(now - timelastframe)) ...
            ' sec idle.']);
    end
    frameNacqd = h.video.FramesAcquired - frameNbase;
    if frameNrecd < frameN
        warning([mfilename ': Received fewer (' ...
            num2str(frameNrecd) ') frames than expected (' ...
            num2str(frameN) ').']);
    end
    totalT = toc;
    frameTsec = totalT / frameNrecd;
    disp([mfilename ': Total frames acquired ' ...
        num2str(frameNacqd) ', expected ' num2str(frameN) '.']);
    disp([mfilename ': Total acquisition and pull time was ' ...
        num2str(totalT) ' sec, expected ' num2str(total_time) ...
        ' sec.']);
    disp([mfilename ': Acquisition and pull time per frame ' ...
        num2str(frameTsec) ' sec, expected ' num2str(total_time / frameN) ...
        ' sec.']);
    % Send pulse to timing DAQ to indicate that acquisition is complete
    outputSingleScan(daqOUTIOI, 0);
    
    clearvars -global Tens FrameTimes
    imagerhandles = h;