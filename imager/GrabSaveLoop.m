function GrabSaveLoop(fname)
    global imagerhandles frameN Tens % GUIhandles FPS
    h = imagerhandles;
    
    % Save after camera buffer contains specific frame number
    frameNchnk = 100;
    % Set whether debugging output should be displayed
    debugToggle = 1;
    % Set whether or not data should be saved (useful during debugging)
    saveToggle = 1;
    
    % Fetch the total set acquisition time
    total_time = str2double(get(findobj('tag', 'timetxt'), 'string'));
    %%% TODO automatically infer this this from stimulus parameters?

    % If in debug mode, display current logging mode setting
    if debugToggle
        disp(['GrabSaveLoop: Camera logging mode set to ' ...
            h.video.LoggingMode])
    end
    
    % Acquire and either save to disk after each frame else buffer and then
    % save all frames at once
    %%% Stream image data to memory buffer and then directly to disk
    %%% after each fetch
    % Turn on strobe for synchronization
    %h.src.Line1LineSource = 'ExposureActive';
    h.src.Strobe1 = 'On';
    if debugToggle
        disp('GrabSaveLoop DEBUG: Strobe set to on.')
    end
    % Start and trigger acquisition
    tic;
    start(h.video)
    trigger(h.video);
    startTime = toc;
    if debugToggle
        disp(['GrabSaveLoop: Time to start and trigger video was ' ...
            num2str(startTime) ' sec.'])
    end
    tic;
    frameNleft = frameN;
    frameNrecd = 0;
    while (h.video.FramesAvailable > 0) || islogging(h.video)
        % Only proceed if new frames exist
        frameNacqd = h.video.FramesAcquired;
        frameNaval = h.video.FramesAvailable;
        if ~isrunning(h.video)
            % Acquisition complete, so turn off strobe
            h.src.Strobe1 = 'Off';
            %h.src.Line1LineSource = 'UserOutput1';
            if debugToggle
                disp('GrabSaveLoop DEBUG: Strobe off.')
            end
        end
        if ~islogging(h.video) && (frameNacqd == frameN)
            % Acquisition done, but frames remain to be fetched
            if debugToggle
                disp(['GrabSaveLoop DEBUG: Finished acquisition ' ...
                    num2str(frameNacqd) ' frames acquired. ' ...
                    num2str(frameNaval) ' remaining on camera.'])
            end
        end
        frameR = (frameNrecd + 1):(frameNrecd + frameNaval);
        if debugToggle
            disp(['GrabSaveLoop DEBUG: ' num2str(frameNacqd) ...
                ' frames acquired. ' num2str(frameNaval) ...
                ' remaining on camera.'])
        end
        frameRnum = length(frameR);
        % Get next frame data from camera
        tget = tic;
        Tens(:,:,frameR) = permute(squeeze(getdata(h.video, frameRnum)), ...
            [2 1 3]);
        getTsec = toc(tget);
        if debugToggle
            disp(['GrabSaveLoop DEBUG: Frames transferred in ' ...
                num2str(getTsec) ' sec.'])
        end
        % Save frames to disk
        if saveToggle
            tsave = tic;
            % Save the buffer to disk as individual frames
            for n = 1:frameRnum
                fn = frameR(n);
                im = Tens(:,:,fn);
                fnamedum = [fname '_' 'f' num2str(fn)];
                save(fnamedum, 'im')
            end
            totalsaveT = toc(tsave);
            clear n im imlast tsave
            if debugToggle
                disp(['GrabSaveLoop DEBUG: Save time for recent '...
                    'fetched frames was ' num2str(totalsaveT) ' sec.'])
                disp(['GrabSaveLoop DEBUG:           per frame ' ...
                    num2str(totalsaveT / frameRnum) ' sec.'])
            end
        end
        % Track frames
        frameNleft = frameNleft - frameRnum;
        frameNrecd = frameNrecd + frameRnum;
        if frameN ~= (frameNleft + frameNrecd)
            if debugToggle
                disp(['GrabSaveLoop DEBUG: Frames received (' ...
                    num2str(frameNrecd) ') and remaining (' ...
                    num2str(frameNleft) ') do not add up to total ' ...
                    'expected (' num2str(frameN) ').'])
            end
        end
    end
    if (frameNleft > 0) || (h.video.FramesAcquired < frameN)
        disp(['GrabSaveLoop ERROR: Fewer frames acquired (' ...
            num2str(h.video.FramesAcquired) ...
            ') than expected (' num2str(frameN) '), leaving some ' ...
            '(' num2str(frameNleft) ') unacquired.'])
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
    %%% Stop acquisition
    stop(h.video)
    if ~isrunning(h.video)
        % Acquisition appears to be complete, turn off strobe
        h.src.Strobe1 = 'Off';
        %h.src.Line1LineSource = 'UserOutput1';
        if debugToggle
            disp('GrabSaveLoop DEBUG: Strobe off.')
        end
    end
    
    imagerhandles = h;
