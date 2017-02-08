function GrabSaveLoop(fname)
    global imagerhandles GUIhandles frameN Tens %FPS
    h = imagerhandles;
    
    % Save after camera buffer contains specific frame number
    frameNchnk = 100;
    % Set whether debugging output should be displayed
    debugToggle = 1;
    % Set whether or not data should be saved (useful during debugging)
    saveToggle = 1;
    
    % Audio pulse settings. Commented 170205 mmf
    %blipeveryN = 1;
    %blipWaveForm = 10 * sin(linspace(0, 2 * pi, 5000*(1/90)));
    %blipSampRate = 5000;
    %h.blip = audioplayer(blipWaveForm, blipSampRate);
    
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
    if ~get(GUIhandles.main.streamFlag, 'value')
        % Stream image data to memory buffer, then save all at once
        % Start acquisition
        if h.video.FramesAcquired == 0
            trigger(h.video);
            disp('GrabSaveLoop: Acquisition triggered.')
        else
            disp('GrabSaveLoop WARNING: Frames acquired prior to trigger.')
            trigger(h.video);
            disp('GrabSaveLoop: Acquisition triggered.')
        end
        tic;
        frameNleft = frameN;
        frameNrecd = 0;
        frameNbin = 0;
        while (h.video.FramesAvailable > 0) || islogging(h.video)
            % Only proceed if new frames exist
            frameNacqd = h.video.FramesAcquired;
            frameNaval = h.video.FramesAvailable;
            if frameNacqd >= (frameNrecd + frameNchnk)
                % Reached frame chunk size, time to pull data
                frameNbin = frameNbin + 1;
                frameNrang = (frameNrecd + 1):(frameNrecd + frameNchnk);
            elseif ~islogging(h.video) && (frameNacqd > frameNrecd)
                % Acquisition done, remaining frames exist
                if (frameNrecd + 1 + frameNaval) < frameN
                    disp(['GrabSaveLoop WARNING: Fewer frames ' ...
                        'received (' num2str(frameNrecd) ') and frames '... 
                        'available (' num2str(frameNaval) ...
                        ') than expected frame total (' ...
                        num2str(frameN) '). Waiting.'])
                    continue
                end
                frameNbin = frameNbin + 1;
                frameNrang = (frameNrecd + 1):(frameNrecd + frameNaval);
            else
                continue
            end
            if debugToggle
                disp(['GrabSaveLoop DEBUG: ' num2str(frameNacqd) ...
                    ' frames acquired. ' num2str(frameNaval) ...
                    ' available on camera.'])
            end
            binN = length(frameNrang);
            if binN > frameNaval
                disp(['GrabSaveLoop ERROR: Attempting to pull more ' ...
                    'frames (' num2str(binN) ' than available on camera (' ...
                    num2str(frameNaval) '). Pull may time out.'])
            end
            % Get next frame data from camera
            tget = tic;
            Tens(:,:,frameNrang) = permute(squeeze(getdata(h.video, binN)), ...
                [2 1 3]);
            getTsec = toc(tget);
            if debugToggle
                disp(['GrabSaveLoop DEBUG: Frame bin ' ...
                    num2str(frameNbin) ' transferred in ' ...
                    num2str(getTsec) ' sec.'])
            end
            % Track frames
            frameNleft = frameNleft - binN;
            frameNrecd = frameNrecd + binN;
            if frameN ~= (frameNleft + frameNrecd)
                if debugToggle
                    disp(['GrabSaveLoop DEBUG: Frames received (' ...
                        num2str(frameNrecd) ') and remaining (' ...
                        num2str(frameNleft) ') do not add up to total ' ...
                        'expected (' num2str(frameN) ').'])
                end
            end
        end
        if (frameNleft > 0) || (frameNacqd < frameN)
            disp(['GrabSaveLoop ERROR: Fewer frames acquired (' ...
                num2str(frameNacqd) ...
                ') than expected (' num2str(frameN) '), leaving some ' ...
                '(' num2str(frameNleft) ') unacquired.'])
        end
        totalT = toc;
        frameTsec = totalT / frameNrecd;
        %FPSactual = 1 / frameTsec;
        disp(['GrabSaveLoop: Total frames acquired ' ...
            num2str(frameNacqd) ', ' num2str(frameN) ' expected.'])
        disp(['GrabSaveLoop: Total acquisition and pull time was ' ...
            num2str(totalT) ' sec, ' num2str(total_time) ...
            ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition and pull time per frame ' ...
            num2str(frameTsec) ' sec, ' num2str(total_time / frameN) ...
            ' sec expected.'])
        %disp(['GrabSaveLoop: Acquisition frames per second ' ...
        %    num2str(FPSactual) ' fps, ' num2str(FPS) ' fps expected.'])
        stop(h.video)
        % Save frames to disk
        if saveToggle
            tsave = tic;
            % Save the buffer to disk as individual frames
            for n = 1:frameN
                im = Tens(:,:,n);
                fnamedum = [fname '_' 'f' num2str(n)];
                save(fnamedum, 'im')
            end
            % Alternatively, save buffer to disk all at once
            %fnamedum = [fname '_' 'fALL'];
            %save(fnamedum, 'Tens', '-v7.3');
            totalsaveT = toc(tsave);
            clear n im imlast
            disp(['GrabSaveLoop: Total save time was ' ...
                num2str(totalsaveT) ' sec.'])
            disp(['GrabSaveLoop: Save time per frame ' ...
                num2str(totalsaveT / frameN) ' sec.'])
        end
    else
        % Stream image data directly to disk after each chunk is pulled
        % Start acquisition
        if h.video.FramesAcquired == 0
            trigger(h.video);
            disp('GrabSaveLoop: Acquisition triggered.')
        else
            disp('GrabSaveLoop WARNING: Frames acquired prior to trigger.')
            trigger(h.video);
            disp('GrabSaveLoop: Acquisition triggered.')
        end
        tic;
        frameNleft = frameN;
        frameNrecd = 0;
        frameNbin = 0;
        while (h.video.FramesAvailable > 0) || islogging(h.video)
            % Only proceed if new frames exist
            frameNacqd = h.video.FramesAcquired;
            frameNaval = h.video.FramesAvailable;
            if frameNacqd >= (frameNrecd + frameNchnk)
                % Reached frame chunk size, time to pull data
                frameNbin = frameNbin + 1;
                frameNrang = (frameNrecd + 1):(frameNrecd + frameNchnk);
            elseif ~islogging(h.video) && (frameNacqd > frameNrecd)
                % Acquisition done, remaining frames exist
                if (frameNrecd + 1 + frameNaval) < frameN
                    disp(['GrabSaveLoop WARNING: Fewer frames ' ...
                        'received (' num2str(frameNrecd) ') and frames '... 
                        'available (' num2str(frameNaval) ...
                        ') than expected frame total (' ...
                        num2str(frameN) '). Waiting.'])
                    continue
                end
                frameNbin = frameNbin + 1;
                frameNrang = (frameNrecd + 1):(frameNrecd + frameNaval);
            else
                continue
            end
            if debugToggle
                disp(['GrabSaveLoop DEBUG: ' num2str(frameNacqd) ...
                    ' frames acquired. ' num2str(frameNaval) ...
                    ' available on camera.'])
            end
            binN = length(frameNrang);
            if binN > frameNaval
                disp(['GrabSaveLoop ERROR: Attempting to pull more ' ...
                    'frames (' num2str(binN) ' than available on camera (' ...
                    num2str(frameNaval) '). Pull may time out.'])
            end
            % Get next frame data from camera
            tget = tic;
            %%% *** XXX TODO make this independent of Tens / big memory
            Tens(:,:,frameNrang) = permute(squeeze(getdata(h.video, binN)), ...
               [2 1 3]);
            getTsec = toc(tget);
            if debugToggle
                disp(['GrabSaveLoop DEBUG: Frame bin ' ...
                    num2str(frameNbin) ' transferred in ' ...
                    num2str(getTsec) ' sec.'])
            end
            % Track frames
            frameNleft = frameNleft - binN;
            frameNrecd = frameNrecd + binN;
            % Save last bin of pulled frames to disk
            if saveToggle
                tsave = tic;
                % Save the buffer to disk as individual frames
                imlast = [];
                for b = 1:binN
                    n = frameNrang(b);
                    im = Tens(:,:,n);
                    fnamedum = [fname '_' 'f' num2str(n)];
                    save(fnamedum, 'im')
                    imlast = im;
                end
                % Alternatively, save chunk buffer to disk all at once
                %fnamedum = [fname '_' 'fALL'];
                %save(fnamedum, 'Tens', '-v7.3');
                totalsaveT = toc(tsave);
                clear n im imlast
                disp(['GrabSaveLoop: Total save time was ' ...
                    num2str(totalsaveT) ' sec.'])
                disp(['GrabSaveLoop: Save time per frame ' ...
                    num2str(totalsaveT / binN) ' sec.'])
            end
            if frameN ~= (frameNleft + frameNrecd)
                if debugToggle
                    disp(['GrabSaveLoop DEBUG: Frames received (' ...
                        num2str(frameNrecd) ') and remaining (' ...
                        num2str(frameNleft) ') do not add up to total ' ...
                        'expected (' num2str(frameN) ').'])
                end
            end
        end
        if (frameNleft > 0) || (frameNacqd < frameN)
            disp(['GrabSaveLoop ERROR: Fewer frames acquired (' ...
                num2str(frameNacqd) ...
                ') than expected (' num2str(frameN) '), leaving some ' ...
                '(' num2str(frameNleft) ') unacquired.'])
        end
        totalT = toc;
        frameTsec = totalT / frameNrecd;
        %FPSactual = 1 / frameTsec;
        disp(['GrabSaveLoop: Total frame number was ' ...
            num2str(frameNacqd) ', ' num2str(frameN) ' expected.'])
        disp(['GrabSaveLoop: Total acquisition and save time was ' ...
            num2str(totalT) ' sec, ' num2str(total_time) ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition and save time per frame ' ...
            num2str(frameTsec) ' sec, ' num2str(total_time / frameN) ...
            ' sec expected.'])
        %disp(['GrabSaveLoop: Acquisition and save frames per second ' ...
        %    num2str(FPSactual) ' fps, ' num2str(FPS) ' fps expected.'])
        stop(h.video)
    end

    imagerhandles = h;

    % Play audio blip for synchronization. Commented out on 170205
    % to see if we can rely on the ttl being sent from the camera.
    %if ~mod(frameNcurr - 1, blipeveryN)
    %    tblip = tic;
    %    %playblocking(h.blip)
    %    sound(blipWaveForm, blipSampRate)
    %    blipTsec = toc(tblip);
    %    if debugToggle
    %        disp(['GrabSaveLoop: Audio blip time ' ...
    %            num2str(blipTsec) ' sec.'])
    %    end
    %end
    
    %%%testing mmf start %%% should be integrated above now
    % DGCH: this is the same as frameN, which is calculated in preallocate.
    % one problem with this code is that there is a constant re-doing of
    % things and changing something in one place fails to have the same
    % effect in another.  let's try to keep it simple
    % N = ceil(total_time*FPS);