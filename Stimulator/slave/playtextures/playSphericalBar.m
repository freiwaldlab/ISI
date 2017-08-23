function playSphericalBar
    % original author Onyekachi 'Kachi' Odoemene 2016-06-30
    global Mstate screenPTR screenNum
    global barTex srcRect dstRect  % from makeSphericalBarTexture
    global Stxtr  % from makeSyncTexture
    syncHigh = Stxtr(1);
    syncLow = Stxtr(2);
    P = getParamStruct;
    window = screenPTR;
    
    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);
    ifi = Screen('GetFlipInterval', window);
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = (white + black) / 2;
    inc = white - grey;

    syncPos = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    syncPiece = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    
    % Set screen to black background before pre-delay
    Screen('FillRect', window, black);
    Screen('Flip', window);
    
    if P.CheckSize ~= 0
        flipRate = P.FlickerRate;
    else
        flipRate = 0;
    end
    direction = P.BarDirection;
    cycleN = P.NumCycles;
    
    % Run the movie animation for a fixed period.
    stimTsec = P.stim_time;
    movTsec = stimTsec / cycleN;
    
    frameRate = Screen('FrameRate', screenNum);
    %temporal period, i.e. number of frames in one cycle of bar sweep
    frameN = floor(frameRate);
    
    % Convert movieDuration in seconds to duration in frames to draw:
    movFrames = round(movTsec * frameRate);
    movFrameInds = floor(mod((0:movFrames-1)/(movFrames/frameN), frameN)) + 1;
    
    if direction == 1 %forward direction
        movFrameInds = reshape(movFrameInds, 1, max(size(movFrameInds)));
        movFrameInds = fliplr(movFrameInds);
    end
    
    if flipRate
        flipFrames = (frameRate / flipRate) / 2; %convert to frames per cycle
        flipBar = floor(mod((0:movFrames)/flipFrames, 2)) + 1;
    else
        flipBar = ones(1, movFrames);
    end
    
    % Translate that into the amount of seconds to wait between screen
    % redraws/updates:
    
    % waitframes = 1 means: Redraw every monitor refresh.
    waitframes = 1;
    
    % Pre-delay
    % Draw "high" sync state for duration of pre-delay block
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay);
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    
    % Play stimulus by drawing pre-generated textures to the screen
    vbl = Screen('Flip', window);
    for n = 1:cycleN
        for i = 1:movFrames
            Screen('DrawTextures', window, ...
                [barTex(flipBar(i), movFrameInds(i)) syncLow], ...
                [srcRect syncPiece], [dstRect syncPos]);
            Screen('DrawingFinished', window);
            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        end
    end
    Screen('FillRect', window, black);
    Screen('Flip', window);

    % Post-delay
    % Draw "high" sync state for duration of post-delay block
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.postdelay);
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);