function GrabSaveLoop(fname)
    global imagerhandles GUIhandles FPS frameN Tens
    h = imagerhandles;
    
    % Set whether debugging output should be displayed
    debugToggle = 1;
    % Set whether or not data should be saved (useful during debugging)
    saveToggle = 0;
    
    % Audio pulse settings
    blipeveryN = 1;
    blipWaveForm = 10 * sin(linspace(0, 2 * pi, 5000*(1/90)));
    blipSampRate = 5000;
    h.blip = audioplayer(blipWaveForm, blipSampRate);
    
    % Fetch the total set acquisition time
    total_time = str2double(get(findobj('Tag', 'timetxt'), 'String'));
    %%% TODO automatically infer this this from stimulus parameters?

    % If in debug mode, display current logging mode setting
    if debugToggle
        disp(['GrabSaveLoop: Logging mode set to: ' h.video.LoggingMode])
    end
    
    % Acquire and either save to disk after each frame else buffer and then
    % save all frames at once
    if ~get(GUIhandles.main.streamFlag, 'value')
        % Stream image data to memory buffer
        % % Start acquisition
        % if h.video.FramesAcquired == 0
        %     trigger(h.video);
        %     disp('GrabSaveLoop: Acquisition triggered.')
        % else
        %     disp('GrabSaveLoop WARNING: Frames acquired prior to trigger.')
        %     trigger(h.video);
        %     disp('GrabSaveLoop: Acquisition triggered.')
        %end
        tic;
        frameNleft = frameN;
        frameNrecd = 0;
        for frameNcurr = 1:frameN
        %while (h.video.FramesAvailable > 0) || islogging(h.video)
            % % Only continue if a new frame exists
            %if h.video.FramesAcquired > frameNrecd
            %    frameNcurr = frameNrecd + 1;
            %else
            %    continue
            %end
            %if debugToggle
            %    disp(['GrabSaveLoop: Frames available = ' ...
            %        num2str(h.video.FramesAvailable)])
            %end
            % Get next frame data from camera
            tget = tic;
            %Tens(:,:,frameNcurr) = permute(getdata(h.video, 1), [2 1]);
            Tens(:,:,frameNcurr) = permute(getsnapshot(h.video), [2 1]);
            getTsec = toc(tget);
            if debugToggle
                disp(['GrabSaveLoop: Frame ' num2str(frameNcurr) ...
                    ' transfer time ' num2str(getTsec) ' sec.'])
            end
            % Play audio blip for synchronization
            if ~mod(frameNcurr - 1, blipeveryN)
                tblip = tic;
                %playblocking(h.blip)
                sound(blipWaveForm, blipSampRate)
                blipTsec = toc(tblip);
                if debugToggle
                    disp(['GrabSaveLoop: Audio blip time ' ...
                        num2str(blipTsec) ' sec.'])
                end
            end
            % Track frames
            frameNleft = frameNleft - 1;
            frameNrecd = frameNcurr;
            if frameN ~= (frameNleft + frameNrecd)
                if debugToggle
                    disp(['GrabSaveLoop ERROR: Frames received (' ...
                        num2str(frameNrecd) ') and remaining (' ...
                        num2str(frameNleft) ') not add up to total ' ...
                        'expected (' num2str(frameN) ').'])
                end
            end
        end
        %frameNacqd = h.video.FramesAcquired;
        frameNacqd = frameNrecd;
        if (frameNleft > 0) || ...
                (frameNacqd < frameN)
            disp(['GrabSaveLoop ERROR: Fewer frames acquired (' ...
                num2str(h.video.FramesAcquired) ...
                ') than expected (' num2str(frameN) '), leaving some ' ...
                '(' num2str(frameNleft) ') unacquired.'])
        end
        totalT = toc;
        frameTsec = totalT / frameN;
        FPSactual = 1 / frameTsec;
        disp(['GrabSaveLoop: Total frame number was ' ...
            num2str(frameNacqd) ', ' num2str(frameN) ' expected.'])
        disp(['GrabSaveLoop: Total acquisition time was ' ...
            num2str(totalT) ' sec, ' num2str(total_time) ...
            ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition time per frame ' ...
            num2str(frameTsec) ' sec, ' num2str(total_time / frameN) ...
            ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition frames per second ' ...
            num2str(FPSactual) ' fps, ' num2str(FPS) ' fps expected.'])
        stop(h.video)
        % Save the buffer to disk as individual frames
        if saveToggle
            tsave = tic;
            imlast = [];
            for n = 1:frameN
                im = Tens(:,:,n);
                if ~isempty(imlast)
                    % Check for two adjacent frames being the same
                    if isequal(imlast, im)
                        disp(['GrabSaveLoop ERROR ERROR ERROR: Frame ' ...
                            num2str(n - 1) ' and ' num2str(n) ...
                            ' are identical.']);
                    end
                end
                fnamedum = [fname '_' 'f' num2str(n)];
                save(fnamedum, 'im')
                imlast = im;
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
        % Stream image data directly to disk
        % % Start acquisition
        % if h.video.FramesAcquired == 0
        %     trigger(h.video);
        %     disp('GrabSaveLoop: Acquisition triggered.')
        % else
        %     disp('GrabSaveLoop WARNING: Frames acquired prior to trigger.')
        %     trigger(h.video);
        %     disp('GrabSaveLoop: Acquisition triggered.')
        % end
        tic;
        frameNleft = frameN;
        frameNrecd = 0;
        for frameNcurr = 1:frameN
        %while islogging(h.video) || ...
        %        (h.video.FramesAvailable > 0)
            % % Only continue if a new frame exists
            % if h.video.FramesAcquired > frameNrecd
            %     frameNcurr = frameNrecd + 1;
            % else
            %     continue
            % end
            % Get next frame data from camera
            tget = tic;
            %im = permute(getdata(h.video, 1), [2 1]);
            im = permute(getsnapshot(h.video), [2 1]);
            getTsec = toc(tget);
            if debugToggle
                disp(['GrabSaveLoop: Frame ' num2str(frameNcurr) ...
                    ' transfer time ' num2str(getTsec) ' sec.'])
            end
            % Play audio blip for synchronization
            tblip = tic;
            %playblocking(h.blip)
            sound(blipWaveForm, blipSampRate);
            blipTsec = toc(tblip);
            if debugToggle
                disp(['GrabSaveLoop: Audio blip time ' ...
                    num2str(blipTsec) ' sec.'])
            end
            if saveToggle
                % Save the frame to disk
                tsave = tic;
                fnamedum = [fname '_' 'f' num2str(frameNcurr)];
                save(fnamedum, 'im')
                saveTsec = toc(tsave);
                if debugToggle
                    disp(['GrabSaveLoop: Frame ' num2str(frameNcurr) ...
                        ' save time ' num2str(saveTsec) ' sec.'])
                end
            end
            % Track frames
            frameNleft = frameNleft - 1;
            frameNrecd = frameNcurr;
            if frameN ~= (frameNleft + frameNrecd)
                if debugToggle
                    disp(['GrabSaveLoop ERROR: Frames received (' ...
                        num2str(frameNrecd) ') and remaining (' ...
                        num2str(frameNleft) ') not add up to total ' ...
                        'expected (' num2str(frameN) ').'])
                end
            end
        end        
        %frameNacqd = h.video.FramesAcquired;
        frameNacqd = frameNrecd;
        if (frameNleft > 0) || ...
                (frameNacqd < frameN)
            disp(['GrabSaveLoop ERROR: Fewer frames acquired (' ...
                num2str(h.video.FramesAcquired) ...
                ') than expected (' num2str(frameN) '), leaving some ' ...
                '(' num2str(frameNleft) ') unacquired.'])
        end
        totalT = toc;
        frameTsec = totalT / frameN;
        FPSactual = 1 / frameTsec;
        disp(['GrabSaveLoop: Total frame number was ' ...
            num2str(frameNacqd) ', ' num2str(frameN) ' expected.'])
        disp(['GrabSaveLoop: Total acquisition and save time was ' ...
            num2str(totalT) ' sec, ' num2str(total_time) ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition and save time per frame ' ...
            num2str(frameTsec) ' sec, ' num2str(total_time / frameN) ...
            ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition and save frames per second ' ...
            num2str(FPSactual) ' fps, ' num2str(FPS) ' fps expected.'])
        stop(h.video)
    end

    imagerhandles = h;
    
%%%testing mmf start %%% should be integrated above now
    % DGCH: this is the same as frameN, which is calculated in preallocate.  
    % one problem with this code is that there is a constant re-doing of 
    % things and changing something in one place fails to have the same
    % effect in another.  let's try to keep it simple
    % N = ceil(total_time*FPS);

% % Keep in mind that using getsnapshot the effectiveFrameRate will be lower
% % than the camera FPS.  Therefore, each recording will have a few extra
% % frames at the end.  Can possibly get around this by using triggered
% % aquisition of set number of frames; however we would lose the ability to
% % record the blips on every frame aquisition.
%  
% % In order to save time, I have the 'sync pulse' being sent over play
% % rather than playblocking.  playblocking was too slow.
%  
% if get(GUIhandles.main.streamFlag,'value')
%      
%     %Pull into matlab and stream directly to disk.  
%     tic;
%     for i = 1:N
%         sound(10 * sin(linspace(0, 2 * pi, 5000/90)), 5000);
%         im = getsnapshot(h.video).';
%         var = ['f' num2str(i)];
%         fnamedum = [fname '_' var];
%         save(fnamedum,'im')
%     end
%     elapsedTime = toc;
%     timePerFrame = elapsedTime/N;
%     effectiveFrameRate = 1/timePerFrame;
%     stop(h.video)
%     disp(['Grabbing frame and saving:' num2str(effectiveFrameRate) ...
%             ' fps, ' num2str(FPS) ' fps expected.']) 
% else
%      
%     %Pull into matlab workspace but wait to save it
%     tic;
%     for i = 1:N
%         sound(10 * sin(linspace(0, 2 * pi, 5000/90)), 5000);
%         Tens(:,:,i) = getsnapshot(h.video).';
%     end
%     elapsedTime = toc;
%     timePerFrame = elapsedTime/N;
%     effectiveFrameRate = 1/timePerFrame;
%     stop(h.video)
%     
% disp(['Grabbing frame only:' num2str(effectiveFrameRate) ...
%             ' fps, ' num2str(FPS) ' fps expected.'])
% disp(['Now saving. Patience necessary.'])
%     
%     tic; 
%     for i = 1:N
%         im = Tens(:,:,i);
%         var = ['f' num2str(i)];
%         fnamedum = [fname '_' var];
%         save(fnamedum,'im')
%     end
%     elapsedTimeSave = toc;
%     timePerFrameSave = elapsedTimeSave/N;
% end
% 
% disp(['Saving frames: Total time' num2str(elapsedTimeSave) ...
%             ' sec, Per frame' num2str(timePerFrameSave) ' sec.'])
%         
% delete(imaqfind)
    

    %%%% Original code.
% % % if get(GUIhandles.main.streamFlag,'value')
% % %     Xpx = IMGSIZE(1);
% % %     Ypx = IMGSIZE(2);
% % %     zz  = zeros(Xpx, Ypx, 'uint16');
% % %     
% % %     %zz = zeros(ROIcrop(3),ROIcrop(4),'uint16'); %mmf
% % %     h.mildig.Grab;
% % %     h.mildig.GrabWait(3);
% % %     
% % %     for n = 1:N
% % % 
% % %         %Wait for grab to finish before switching the buffers
% % %         h.mildig.GrabWait(3);
% % % 
% % %         %Switch destination, then grab to it (asynchronously)
% % %         h.mildig.Image = h.buf{bitand(n,1)+1};
% % %         h.mildig.Grab;
% % % 
% % %         %TTL pulse
% % %         % Updated for MATLAB compatibility, 170109 mmf
% % %         %putvalue(parport,1); putvalue(parport,0);
% % %         playblocking(h.blip);
% % % 
% % %         %Pull into Matlab workspace and save to disk
% % %         im = h.buf{2-bitand(n,1)}.Get(zz,IMGSIZE^2,-1,ROIcrop(1),ROIcrop(2),ROIcrop(3),ROIcrop(4));
% % %         var = ['f' num2str(n)];
% % %         fnamedum = [fname '_' var];
% % %         save(fnamedum,'im')
% % %     end
% % % else
% % %     zz = zeros(ROIcrop(3),ROIcrop(4),'uint16');
% % %     h.mildig.Grab;
% % %     h.mildig.GrabWait(3);
% % % 
% % %     for n = 1:N
% % %         %Wait for grab to finish before switching the buffers
% % %         h.mildig.GrabWait(3);
% % % 
% % %         %Switch destination, then grab to it (asynchronously)
% % %         h.mildig.Image = h.buf{bitand(n,1)+1};
% % %         h.mildig.Grab;
% % % 
% % %         %TTL pulse
% % %         % Updated for MATLAB compatibility, 170109 mmf
% % %         %putvalue(parport,1); putvalue(parport,0);
% % %         playblocking(h.blip);
% % % 
% % %         %Pull into Matlab workspace (but wait to save it)
% % %         Tens(:,:,n) = h.buf{2-bitand(n,1)}.Get(zz,IMGSIZE^2,-1,ROIcrop(1),ROIcrop(2),ROIcrop(3),ROIcrop(4));
% % %     end
% % %     
% % %     tic
% % %     for n = 1:N        
% % %         im = Tens(:,:,n);
% % %         var = ['f' num2str(n)];
% % %         fnamedum = [fname '_' var];
% % %         save(fnamedum,'im')        
% % %     end
% % %     toc
% % % 
% % % end