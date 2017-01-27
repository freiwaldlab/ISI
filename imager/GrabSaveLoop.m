function GrabSaveLoop(fname)
    global imagerhandles GUIhandles FPS frameN Tens effectiveFrameRate
    h = imagerhandles;
    
    % Set whether debugging output should be displayed
    debugToggle = 0;

    % Fetch the total set acquisition time
    total_time = str2double(get(findobj('Tag', 'timetxt'), 'String'));
    %%% TODO automatically infer this this from stimulus parameters?

    % Acquire and either save to disk after each frame else buffer and then
    % save all frames at once
    if ~get(GUIhandles.main.streamFlag, 'value')
        % Stream image data to memory buffer
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
        while islogging(h.video) || ...
                (h.video.FramesAvailable > 0)
            % Only continue if a new frame exists
            if h.video.FramesAcquired > frameNrecd
                frameNcurr = frameNrecd + 1;
            else
                continue
            end
            % Play audio blip for synchronization
            tblip = tic;
            play(h.blip)
            blipTsec = toc(tblip);
            if debugToggle
                disp(['GrabSaveLoop: Audio blip time ' ...
                    num2str(blipTsec) ' sec.'])
            end
            % Get next frame data from camera
            tget = tic;
            Tens(:,:,frameNcurr) = permute(getdata(h.video, 1), [2 1]);
            getTsec = toc(tget);
            if debugToggle
                disp(['GrabSaveLoop: Frame ' num2str(frameNcurr) ...
                    ' transfer time ' num2str(getTsec) ' sec.'])
            end
            % Track frames
            frameNleft = frameNleft - 1;
            frameNrecd = frameNcurr;
            if frameN ~= (frameNleft + frameNrecd)
                if debugToggle
                    disp(['GrabSaveLoop ERROR: Frames received ' ...
                        'and remaining do not add up to total.'])
                end
            end
        end
        if (frameNleft > 0) || ...
                (h.video.FramesAcquired < frameN)
            disp(['GrabSaveLoop ERROR: Fewer frames acquired than ' ...
                'expected.'])
        end
        totalT = toc;
        frameTsec = totalT / frameN;
        effectiveFrameRate = 1 / frameTsec;
        disp(['GrabSaveLoop: Total acquisition time was ' ...
            num2str(totalT) ' sec, ' num2str(total_time) ...
            ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition time per frame ' ...
            num2str(frameTsec) ' sec, ' num2str(effectiveFrameRate) ...
            ' fps, ' num2str(FPS) ' fps expected.'])
        stop(h.video)
        % Save the buffer to disk as individual frames
        tic;
        for n = 1:frameN
            im = Tens(:,:,n);
            fnamedum = [fname '_' 'f' num2str(n)];
            save(fnamedum, 'im')          
        end
        totalsaveT = toc;
        disp(['GrabSaveLoop: Total save time was ' ...
            num2str(totalsaveT) ' sec.'])
        disp(['GrabSaveLoop: Save time per frame ' ...
            num2str(totalsaveT / frameN) ' sec.'])
    else
        % Stream image data directly to disk
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
        while islogging(h.video) || ...
                (h.video.FramesAvailable > 0)
            % Only continue if a new frame exists
            if h.video.FramesAcquired > frameNrecd
                frameNcurr = frameNrecd + 1;
            else
                continue
            end
            % Play audio blip for synchronization
            tblip = tic;
            play(h.blip)
            blipTsec = toc(tblip);
            if debugToggle
                disp(['GrabSaveLoop: Audio blip time ' ...
                    num2str(blipTsec) ' sec.'])
            end
            % Get next frame data from camera
            tget = tic;
            im = permute(getdata(h.video, 1), [2 1]);
            getTsec = toc(tget);
            if debugToggle
                disp(['GrabSaveLoop: Frame ' num2str(frameNcurr) ...
                    ' transfer time ' num2str(getTsec) ' sec.'])
            end
            % Save the frame to disk
            tsave = tic;
            fnamedum = [fname '_' 'f' num2str(frameNcurr)];
            save(fnamedum, 'im')
            saveTsec = toc(tsave);
            if debugToggle
                disp(['GrabSaveLoop: Frame ' num2str(frameNcurr) ...
                    ' transfer time ' num2str(saveTsec) ' sec.'])
            end
            % Track frames
            frameNleft = frameNleft - 1;
            frameNrecd = frameNcurr;
            if frameN ~= (frameNleft + frameNrecd)
                if debugToggle
                    disp(['GrabSaveLoop ERROR: Frames received ' ...
                        'and remaining do not add up to total.'])
                end
            end
        end        
        if (frameNleft > 0) || ...
                (h.video.FramesAcquired < frameN)
            disp(['GrabSaveLoop ERROR: Fewer frames acquired than ' ...
                'expected.'])
        end
        totalT = toc;
        frameTsec = totalT / frameN;
        effectiveFrameRate = 1 / frameTsec;
        disp(['GrabSaveLoop: Total acquisition and save time was ' ...
            num2str(totalT) ' sec, ' num2str(total_time) ' sec expected.'])
        disp(['GrabSaveLoop: Acquisition and save time per frame ' ...
            num2str(frameTsec) ' sec, ' num2str(effectiveFrameRate) ...
            ' fps, ' num2str(FPS) ' fps expected.'])
        stop(h.video)
    end
    
    % Remove video object and clean up 
    delete(h.video);
    clear h.video
    imagerhandles = h;

% % if get(GUIhandles.main.streamFlag,'value')
% %     Xpx = IMGSIZE(1);
% %     Ypx = IMGSIZE(2);
% %     zz  = zeros(Xpx, Ypx, 'uint16');
% %     
% %     %zz = zeros(ROIcrop(3),ROIcrop(4),'uint16'); %mmf
% %     h.mildig.Grab;
% %     h.mildig.GrabWait(3);
% %     
% %     for n = 1:N
% % 
% %         %Wait for grab to finish before switching the buffers
% %         h.mildig.GrabWait(3);
% % 
% %         %Switch destination, then grab to it (asynchronously)
% %         h.mildig.Image = h.buf{bitand(n,1)+1};
% %         h.mildig.Grab;
% % 
% %         %TTL pulse
% %         % Updated for MATLAB compatibility, 170109 mmf
% %         %putvalue(parport,1); putvalue(parport,0);
% %         playblocking(h.blip);
% % 
% %         %Pull into Matlab workspace and save to disk
% %         im = h.buf{2-bitand(n,1)}.Get(zz,IMGSIZE^2,-1,ROIcrop(1),ROIcrop(2),ROIcrop(3),ROIcrop(4));
% %         var = ['f' num2str(n)];
% %         fnamedum = [fname '_' var];
% %         save(fnamedum,'im')
% %     end
% % else
% %     zz = zeros(ROIcrop(3),ROIcrop(4),'uint16');
% %     h.mildig.Grab;
% %     h.mildig.GrabWait(3);
% % 
% %     for n = 1:N
% %         %Wait for grab to finish before switching the buffers
% %         h.mildig.GrabWait(3);
% % 
% %         %Switch destination, then grab to it (asynchronously)
% %         h.mildig.Image = h.buf{bitand(n,1)+1};
% %         h.mildig.Grab;
% % 
% %         %TTL pulse
% %         % Updated for MATLAB compatibility, 170109 mmf
% %         %putvalue(parport,1); putvalue(parport,0);
% %         playblocking(h.blip);
% % 
% %         %Pull into Matlab workspace (but wait to save it)
% %         Tens(:,:,n) = h.buf{2-bitand(n,1)}.Get(zz,IMGSIZE^2,-1,ROIcrop(1),ROIcrop(2),ROIcrop(3),ROIcrop(4));
% %     end
% %     
% %     tic
% %     for n = 1:N        
% %         im = Tens(:,:,n);
% %         var = ['f' num2str(n)];
% %         fnamedum = [fname '_' var];
% %         save(fnamedum,'im')        
% %     end
% %     toc
% % 
% % end