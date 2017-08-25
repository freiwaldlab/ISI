function playSphericalBar
    % Original author Onyekachi 'Kachi' Odoemene 2016-06-30
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
    cycleN = P.NumCycles;
    
    % Run the movie animation for a fixed period.
    stimTsec = P.stim_time;
    movTsec = stimTsec / cycleN;
    
    frameRate = Screen('FrameRate', screenNum);
    %temporal period, i.e. number of frames in one cycle of bar sweep
    frameN = floor(frameRate);
    
    % Convert movTsec to duration in frames.
    movFrms = round(movTsec * frameRate);
    movFrmInds = floor(mod((0:movFrms-1)/(movFrms/frameN), frameN)) + 1;
    
    if P.BarDirection == 1
    % Forward direction
        movFrmInds = reshape(movFrmInds, 1, max(size(movFrmInds)));
        movFrmInds = fliplr(movFrmInds);
        disp([mfilename ': Presenting bar in forward direction.']);
    elseif P.BarDirection == -1
    % Reverse direction
        disp([mfilename ': Presenting bar in reverse direction.']);
    else
        movFrmInds = reshape(movFrmInds, 1, max(size(movFrmInds)));
        movFrmInds = fliplr(movFrmInds);
        disp([mfilename ': Direction incorrectly specified, ' ...
            'defaulting to forward.']);
    end
    
    if flipRate
        flipFramesPerCyc = (frameRate / flipRate) / 2;
        flipBar = floor(mod((0:movFrms)/flipFramesPerCyc, 2)) + 1;
    else
        flipBar = ones(1, movFrms);
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
        for i = 1:movFrms
            Screen('DrawTextures', window, ...
                [barTex(flipBar(i), movFrmInds(i)) syncLow], ...
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