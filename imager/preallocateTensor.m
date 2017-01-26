function preallocateTensor

global FPS Tens IMGSIZE GUIhandles %ROIcrop

 total_time =  str2num(get(findobj('Tag','timetxt'),'String'));
 maxframes = ceil(total_time*FPS)
 
 % set up image aquisition object
 handles.video = videoinput('pointgrey', 1, 'F7_Raw16_1920x1200_Mode0');
 triggerconfig(handles.video, 'manual');
 handles.video.TriggerRepeat = Inf;
 start(handles.video)
 
if get(GUIhandles.main.analysisFlag,'value') || ~get(GUIhandles.main.streamFlag,'value')            
    Xpx = IMGSIZE(1);
    Ypx = IMGSIZE(2);
    Tens = zeros(Xpx,Ypx,maxframes,'uint16');
    %Tens = zeros(ROIcrop(3),ROIcrop(4),maxframes,'uint16');
else
    Tens = 0;
end
