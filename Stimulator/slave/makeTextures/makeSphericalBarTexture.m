function makeSphericalBarTexture
% original author: Onyekachi 'Kachi' Odoemene 2016-06-30
%drifting bar stimulus i.e. full field drifting grating
    global Mstate screenPTR screenNum
    global barTex srcRect dstRect
    P = getParamStruct;
    window = screenPTR;

    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = (white + black) / 2;
    inc = white - grey;
    
    barThickDeg = P.BarThickness;
    checkXYdeg = P.CheckSize;
    flick_rate = P.FlickerRate;
    bar_ori = P.BarOrient;

    screenDcm = Mstate.screenDist; %in cm, needs to be converted to pixels
    w = Mstate.screenXcm; %width of monitor
    h = Mstate.screenYcm; %height of monitor
    cx = P.eyeXLocation; %eye x location, cm
    cy = P.eyeYLocation; %eye y location, cm
    
    zdistTop = hypot(screenDcm, h - cy); %distance from eye to top of screen
    zdistBottom = hypot(screenDcm, cy); %distance from eye to bottom of screen
    
    scale = P.ScreenScaleFactor;
    pxXmax = screenRes.width / scale;
    pxYmax = screenRes.height / scale;
    resXpxpercm = round(pxXmax / w);
    resYpxpercm = round(pxYmax / h);
    
    %internal conversions?
    top = h - cy;
    bottom = -cy;
    right = cx;
    left = cx - w;
    
    [xi,yi] = meshgrid(1:pxXmax,1:pxYmax);
    cart_pointsX = left + (w/pxXmax).*xi;
    cart_pointsY = top - (h/pxYmax).*yi;
    cart_pointsZ = zdistTop + ((zdistBottom - zdistTop)/pxYmax).*yi;
    [sphr_pointsTh, sphr_pointsPh, ~] = cart2sph(cart_pointsZ,cart_pointsX,cart_pointsY);
    
    %rescale Cartesian maps into dimensions of radians
    xmaxRad = max(sphr_pointsTh(:));
    ymaxRad = max(sphr_pointsPh(:));
    fx = xmaxRad / max(cart_pointsX(:));
    fy = ymaxRad / max(cart_pointsY(:));
    
    % determine stimulus size in pixels
    % barThicknessPixels = round(tan(barThicknessDeg)*screenDistance
    texsizeY = ceil(pxXmax / 2);
    texsizeZ = ceil(pxYmax / 2);
    
    % This is the visible size of the texture. It is twice the half-width
    % of the texture plus one pixel to make sure it has an odd number of
    % pixels and is therefore symmetric around the center of the texture:
    visiblesizeX = 2*texsizeY + 1;
    visiblesizeY = 2*texsizeZ + 1;
    
    %% define destination of stimuli
    frameRate = Screen('FrameRate', screenNum);
    if frameRate == 0
        warning([mfilename ': FrameRate for screen returned 0Hz.  Assuming 60Hz.']);
        frameRate = 60;
    end
    Mstate.screenFrameRate = frameRate;
    %temporal period, i.e. number of frames in one cycle of bar sweep
    frameN = floor(frameRate);
    barThicknesscm = tan(barThickDeg * pi/180) * screenDcm;
    barXThickness = round(barThicknesscm * resXpxpercm); %vertical bar
    barYThickness = round(barThicknesscm * resYpxpercm); %horizontal bar
    
    if bar_ori
        % horizontal bar, altitude travel
        barAngle = 90;
        barThickness = barYThickness;
        thisScreenSize = pxYmax + 2*barThickness;
    else
        % vertical bar, azimuth travel
        barAngle = 0;
        barThickness = barXThickness;
        thisScreenSize = pxXmax + 2*barThickness;
    end
    cyclesPerPixel = 1 / thisScreenSize;
    dutyCycle = 1 - (barThickness / thisScreenSize); %determines bar thickness
    
    % Generate grating
    [x,y] = meshgrid(-pxXmax/2:pxXmax/2-1, -pxYmax/2:pxYmax/2-1);
    
    angle = barAngle * pi/180;
    f = cyclesPerPixel * 2*pi; % cycles/pixel
    
    a = f*cos(angle);
    b = f*sin(angle);
    
    %flipInds = ones(1, frameN); % start with non-flickering checkerboard
    %bars = ones(pxYmax, pxXmax, 2);
    chkbar = ones(pxYmax, pxXmax);
    if checkXYdeg > 0
        checkXYcm = screenDcm * tan(checkXYdeg * pi/180);
        checkXYpx = round(checkXYcm * resYpxpercm);
        checkPtrn = double(checkerboard(checkXYpx, ...
            1+round((pxYmax/2)/checkXYpx), ...
            1+round((pxXmax/2)/checkXYpx))<0.5);
        checkPtrn = checkPtrn(1:pxYmax,1:pxXmax);
        chkbar = checkPtrn;
        %chkbar(:,:,1) = checkPtrn;
        %chkbar(:,:,2) = abs(1 - checkPtrn);
        %if flick_rate > 0
        %    %convert to frames per cycle
        %    flipFrames = (frameRate / flick_rate) / 2;
        %    flipInds = floor(mod((0:frameN) / flipFrames, 2)) + 1;
        %end
    end
    
    barTex = nan(2, frameN);
    for f = 1:frameN
        %controls movement
        phase = ((f-1) / (frameN-1))*2*pi;
        %from DriftDemo2.m and Ian Nauhaus' code makePerGratFrame_insep.m
        img = cos(a*x + b*y + phase);
        img = sign(img - cos(dutyCycle*pi));
        img = double(img < 0);
        
        thisBar = chkbar;
        flipBar = abs(1 - chkbar);
        %thisBar = chkbar(:,:,flipInds(f));
        thisImg = img .* thisBar;
        flipImg = img .* flipBar;
        if P.sphereCorrectON
            thisImg = interp2(cart_pointsX .* fx, cart_pointsY .* fy, ...
                thisImg, sphr_pointsTh, sphr_pointsPh);
            flipImg = interp2(cart_pointsX .* fx, cart_pointsY .* fy, ...
                flipImg, sphr_pointsTh, sphr_pointsPh);
        end
        thisImg = white * thisImg;
        flipImg = white * flipImg;
        barTex(1,f) = Screen('MakeTexture', screenPTR, thisImg);
        barTex(2,f) = Screen('MakeTexture', screenPTR, flipImg);
    end
    
    srcRect = [0 0 visiblesizeX visiblesizeY]';  % texture size
    dstRect = [0 0 pxXmax*scale pxYmax*scale]';  % scale to screen