function playcohmotion
    global Mstate screenPTR screenNum
    global DotFrame  % from makeCohMotion
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
    % ifi = Screen('GetFlipInterval', window);
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = (white + black) / 2;
    inc = white - grey;
    %if strcmp(P.altazimuth, 'none')
    %    stimWcm = 2 * pi * Mstate.screenDist * (P.x_size / 360);
    %    stimWpx = round(resXpxpercm * stimWcm);
    %    stimHcm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
    %    stimHpx = round(resYpxpercm * stimHcm);
    %else
    %    stimWcm = 2 * Mstate.screenDist * tan((P.x_size / 2) * (pi / 180));
    %    stimWpx = round(resXpxpercm * stimWcm);
    %    stimHcm = 2 * Mstate.screenDist * tan((P.y_size / 2) * (pi / 180));
    %    stimHpx = round(resYpxpercm * stimHcm);
    %end
    %rngXpx = [(P.x_pos - floor(stimWpx / 2) + 1) ...
    %    (P.x_pos + ceil(stimWpx / 2))];
    %rngYpx = [(P.y_pos - floor(stimHpx / 2) + 1) ...
    %    (P.y_pos + ceil(stimHpx / 2))];
    syncPos = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    syncPiece = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    %stimPos = [rngXpx(1) rngYpx(1) rngXpx(2) rngYpx(2)]';
    %stimPiece = [0 0 imWpx imHpx]';

    dotDcm = ((P.sizeDots * 2 * pi) / 360) * Mstate.screenDist;
    dotDpx = round(dotDcm * resXpxpercm);
    stimNframes = ceil(P.stim_time * screenRes.hz);
    
    Screen(window, 'FillRect', P.background)
    
    if P.contrast == 0
        r = P.background;
        g = P.background;
        b = P.background;
    else
        r = P.redgun;
        g = P.greengun;
        b = P.bluegun;
    end
    
    % Pre-delay
    % Draw "high" sync state for first half of pre-delay to indicate 
    % beginning of new block
    Screen('DrawDots', window, DotFrame{1}, dotDpx, [r g b], ...
        [P.x_pos P.y_pos], P.dotType);
    Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);
    Screen('DrawDots', window, DotFrame{1}, dotDpx, [r g b], ...
        [P.x_pos P.y_pos], P.dotType);
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);
    
    % Play stimulus
    Screen('DrawDots', window, DotFrame{1}, dotDpx, [r g b], ...
        [P.x_pos P.y_pos], P.dotType);
    Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
    Screen('Flip', window);
    for i = 2:stimNframes
        Screen('DrawDots', window, DotFrame{i}, dotDpx, [r g b], ...
            [P.x_pos P.y_pos], P.dotType);
        Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
        Screen('Flip', window);
    end
    
    % Post-delay
    % Draw "low" sync state for duration of post-delay block
    %Screen('DrawDots', window, DotFrame{stimNframes}, dotDpx, [r g b], ...
    %    [P.x_pos P.y_pos], P.dotType);
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.postdelay);
    Screen(window, 'FillRect', P.background)