function handout = configVideoInput(handin, trigtype)
    global FPS IMGSIZE Mstate
    handout = handin;
    
    %%% Camera initialization
    % Using PointGrey adaptor in MATLAB 2016
    handout.src = getselectedsource(handout.video);
    switch trigtype
        case 'immediate'
            triggerconfig(handout.video, 'immediate');
        case 'manual'
            triggerconfig(handout.video, 'manual');
        case 'hardware'
            triggerconfig(handout.video, 'hardware', ...
                'risingEdge', 'externalTriggerMode14-Source0');
    end
    %ti = triggerinfo(handout.video);
    
    %%%% Camera settings
    handout.video.FramesPerTrigger = 1;
    handout.video.TriggerRepeat = Inf;
    handout.src.PacketSize = 9000;
    handout.src.PacketDelay = 1400;
    handout.src.Strobe1Polarity = 'High';
    % In Blackfly mode0, the shutter setting determines the exposure value
    handout.src.Shutter = 50;
    handout.src.Strobe1 = 'On';
    handout.src.Strobe1Delay = 0;
    % Fix gain to max so no automatic adjustments are made
    handout.src.Gain = 29.9964;
    %handout.src.ExposureMode = 'Manual';
    handout.src.Strobe1Duration = handout.src.Shutter;
    FPS = floor(handout.src.FrameRate);
    Mstate.FrameRate = FPS;
    IMGSIZE = handout.video.VideoResolution;

    % Using GigE adaptor in MATLAB 2015 (broken)
    %handout.video = videoinput('gige', 1, 'Mono16');
    %handout.src = getselectedsource(handout.video);
    %triggerconfig(handout.video, 'hardware');
    % %ti = triggerinfo(handout.video);
    % %handout.video.TriggerRepeat = Inf;
    %handout.video.FramesPerTrigger = 1;
    %handout.src.FrameStartTriggerMode = 'On';
    %handout.src.FrameStartTriggerSource = 'Line0';
    %handout.src.FrameStartTriggerActivation = 'RisingEdge';
    %handout.src.FrameStartTriggerOverlap = 'ReadOut';
    %handout.src.Line1LineSource = 'ExternalTriggerActive';
    %handout.src.Line1StrobeDuration = 10;
    % %handout.src.Line0LineStatus = 'True';
    % %handout.src.Line1LineStatus = 'True';
    
    % Using GigE adaptor in MATLAB 2016 (broken)
    %handout.video = videoinput('gige', 1, 'Mono16');
    %handout.src = getselectedsource(handout.video);
    %triggerconfig(handout.video, 'hardware', ...
    %   'risingEdge', 'externalTriggerMode14-Source0');
    % %ti = triggerinfo(handout.video);
    %handout.src.LineSelector = 'Line1';
    %handout.src.TriggerActivation = 'RisingEdge';
    %handout.src.StrobeDuration = 10;