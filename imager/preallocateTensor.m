function preallocateTensor
    global imagerhandles FPS Tens IMGSIZE frameN daqOUTtrig trigSeq %GUIhandles
    h = imagerhandles;
    
    % Set whether debugging output should be displayed
    debugToggle = 1;
    
    total_time = str2double(get(findobj('Tag', 'timetxt'), 'String'));
    frameN = ceil(total_time * FPS);

    % Pre-allocate storage of imaging data          
    Xpx = IMGSIZE(1);
    Ypx = IMGSIZE(2);
    Tens = zeros(Xpx, Ypx, frameN, 'uint16');

    h = configVideoInput(h, 'hardware');

    %%% Create camera hardware trigger sequence
    msec_per_frame = ceil(1000 / FPS);
    highV = 5;
    dutyCycle = 0.1;
    trigSingle = zeros(msec_per_frame, 1);
    % assuming a frame rate of 10fps, a duty cycle of 10%, and a rising
    % edge trigger, then first 90 should be 0 and last 10 should be 5V
    trigSingle(end-round(dutyCycle*length(trigSingle))-1:end-1) = highV;
    % Now we have one cycle, use repmat to make frameN copies
    trigSeq = repmat(trigSingle, [frameN, 1]);
    outRate = daqOUTtrig.Rate;
    cushion = zeros(outRate * ceil(size(trigSeq, 1) / outRate) - ...
        size(trigSeq, 1), 1);
    trigSeq = [trigSeq; cushion];
    %lhOut = addlistener(daqOUTtrig, 'DataRequired', ...
    %   @(src,event) src.queueOutputData(trigSeq));

    tic;
    start(h.video);
    startTime = toc;
    if debugToggle
       disp(['preallocateTensor: Time to start video input was ' ...
           num2str(startTime) ' sec.'])
    end
    
    imagerhandles = h;