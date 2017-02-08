function preallocateTensor
    global imagerhandles FPS Tens IMGSIZE frameN %GUIhandles
    h = imagerhandles;
    
    % Set whether debugging output should be displayed
    debugToggle = 1;
    
    total_time = str2double(get(findobj('Tag', 'timetxt'), 'String'));
    frameN = ceil(total_time * FPS);

    % Pre-allocate storage of imaging data
    %if get(GUIhandles.main.analysisFlag, 'value') || ...
    %        ~get(GUIhandles.main.streamFlag, 'value')            
    Xpx = IMGSIZE(1);
    Ypx = IMGSIZE(2);
    Tens = zeros(Xpx, Ypx, frameN, 'uint16');
    %else
    %    Tens = 0;
    %end

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
    % Camera settings
    %h.video.TriggerRepeat = Inf;
    %h.video.FramesPerTrigger = 1; % similar to GETSNAPSHOT approach
    h.video.FramesPerTrigger = frameN;
    %h.video.TriggerRepeat = Inf;
    h.src = getselectedsource(h.video);
    
    %h.src.Brightness = 2.9297;
    %h.src.Exposure = -2.415;
    %h.src.ExposureMode = Auto';
    h.src.FrameRate = 18;
    %h.src.FrameRateMode = 'Auto';
    %h.src.Gain = 29.9964;
    %h.src.GainMode = 'Auto';
    %h.src.PacketDelay = 400;
    %h.src.PacketSize = 1400;
    %h.src.Shutter = 54.7252;
    %h.src.ShutterMode = 'Auto';
    h.src.Strobe1 = 'On';
    h.src.Strobe1Delay = 0;
    h.src.Strobe1Duration = 0.8 * ((1000 / h.src.FrameRate) / 4);
    disp(['preallocateTensor DEBUG: strobe duration ' ...
        num2str(h.src.Strobe1Duration)])
    h.src.Strobe1Polarity = 'High';
    %h.src.TriggerDelay = 0;
    %h.src.TriggerDelayMode = 'Manual';
    %h.src.TriggerParameter = 1;

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