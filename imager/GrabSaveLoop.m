function [h] = GrabSaveLoop(h, fname)
% Deleted 170110 mmf, parport removed from function inputs
global Tens ROIcrop IMGSIZE GUIhandles FPS effectiveFrameRate

total_time =  str2double(get(findobj('Tag','timetxt'),'String'));
N = ceil(total_time*FPS);

% Keep in mind that using getsnapshot the effectiveFrameRate will be lower
% than the camera FPS.  Therefore, each recording will have a few extra
% frames at the end.  Can possibly get around this by using triggered
% aquisition of set number of frames; however we would lose the ability to
% record the blips on every frame aquisition.

% In order to save time, I have the 'sync pulse' being sent over play
% rather than playblocking.  playblocking was too slow.

if get(GUIhandles.main.streamFlag,'value')
    
    %Pull into matlab and stream directly to disk.  
    tic;
    for i = 1:N
        play(handles.blip)
        im = getsnapshot(handles.video);
        var = ['f' num2str(i)];
        fnamedum = [fname '_' var];
        save(fnamedum,'im')
    end
    elapsedTime = toc;
    timePerFrame = elapsedTime/20;
    effectiveFrameRate = 1/timePerFrame;
    stop(handles.video)
    
else
    
    %Pull into matlab workspace but wait to save it
    tic;
    for n = 1:N
        play(handles.blip)
        Tens(:,:,n) = getsnapshot(handles.video);
    end
    elapsedTime = toc;
    timePerFrame = elapsedTime/20;
    effectiveFrameRate = 1/timePerFrame;
    stop(handles.video)
    
    for n = 1:N
        im = Tens(:,:,n);
        var = ['f' num2str(n)];
        fnamedum = [fname '_' var];
        save(fnamedum,'im')
    end
    
end

delete(imaqfind)

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