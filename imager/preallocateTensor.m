function preallocateTensor
    global imagerhandles GUIhandles FPS Tens IMGSIZE frameN
    h = imagerhandles;
    
    % Set whether debugging output should be displayed
    debugToggle = 1;
    
    total_time = str2double(get(findobj('Tag', 'timetxt'), 'String'));
    frameN = ceil(total_time * FPS);

    % Pre-allocate storage of imaging data
    if get(GUIhandles.main.analysisFlag, 'value') || ...
            ~get(GUIhandles.main.streamFlag, 'value')            
        Xpx = IMGSIZE(1);
        Ypx = IMGSIZE(2);
        Tens = zeros(Xpx, Ypx, frameN, 'uint16');
    else
        Tens = 0;
    end

    % Set up image aquisition object here in order to save time when
    % GrabSaveLoop is called
    tic;
    if ~isempty(h.video)
        disp(['preallocateTensor WARNING: Video device already in use.' ...
            ' Closing before trying to open.'])
        % Delete any preview image acquisition objects
        delete(h.video)
        clear h.video
    end
    h.video = videoinput('pointgrey', 1, 'F7_Raw16_1920x1200_Mode0');
    triggerconfig(h.video, 'manual');
    % If in manual trigger mode and relying on GETSNAPSHOT, 
    %h.video.TriggerRepeat = Inf;
    h.video.FramesPerTrigger = 1; %frameN;
    %h.video.FrameRate
    setupTime = toc;
    if debugToggle
        disp(['preallocateTensor: Time to setup video input was ' ...
            num2str(setupTime) ' sec.'])
    end
    % Start, because actual acquisition won't start until manually
    % triggered
    tic;
    start(h.video)
    startTime = toc;
    if debugToggle
        disp(['preallocateTensor: Time to start video pre-trigger was ' ...
            num2str(startTime) ' sec.'])
    end
    
    imagerhandles = h;