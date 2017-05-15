function playgrating_flashCartesian
%This one uses the sequences that were already defined in the make file
    global Mstate screenPTR screenNum
    global Gtxtr  % from makeGratingTexture_flashCartesia
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
    stimWcm = 2 * pi * Mstate.screenDist * (P.x_size / 360);
    stimWpx = round(resXpxpercm * stimWcm);
    stimHcm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
    stimHpx = round(resYpxpercm * stimHcm);
    %if strcmp(P.altazimuth, 'none')
    %   stimWcm = 2 * pi * Mstate.screenDist * (P.x_size / 360);
    %   stimWpx = round(resXpxpercm * stimWcm);
    %   stimHcm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
    %   stimHpx = round(resYpxpercm * stimHcm);
    %else
    %   stimWcm = 2 * Mstate.screenDist * tan((P.x_size / 2) * (pi / 180));
    %   stimWpx = round(resXpxpercm * stimWcm);
    %   stimHcm = 2 * Mstate.screenDist * tan((P.y_size / 2) * (pi / 180));
    %   stimHpx = round(resYpxpercm * stimHcm);
    %end
    rngXpx = [(P.x_pos - floor(stimWpx / 2) + 1) ...
       (P.x_pos + ceil(stimWpx / 2))];
    rngYpx = [(P.y_pos - floor(stimHpx / 2) + 1) ...
       (P.y_pos + ceil(stimHpx / 2))];
    syncPos = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    syncPiece = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    stimPos = [rngXpx(1) rngYpx(1) rngXpx(2) rngYpx(2)]';
    %stimPiece = [0 0 imWpx imHpx]';
    stimNframes = round((P.stim_time * screenRes.hz) / P.h_per);

    Screen(window, 'FillRect', P.background)

    % Pre-delay
    % Draw "high" sync state for first half of pre-delay to indicate 
    % beginning of new block
    Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);

    % Play stimulus
    %Unlike periodic grater, this doesn't produce a digital sync on last frame, just
    %the start of each grating.  But this one will always show 'h_per' frames on
    %the last grating, regardless of 'stimtime'.
    for i = 1:stimNframes
        Screen('DrawTextures', screenPTR, ...
            [Gtxtr(i) Stxtr(2-rem(i,2))], [], [stimPos syncPos]);
        Screen(screenPTR, 'Flip');
        for j = 2:P.h_per %sync flips on each update
            Screen('DrawTextures', screenPTR, ...
                [Gtxtr(i) Stxtr(2-rem(i,2))], [], [stimPos syncPos]);
            Screen(screenPTR, 'Flip');
        end
    end
    
    % Post-delay
    % Draw "low" sync state for duration of post-delay block
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.postdelay);
    Screen(window, 'FillRect', P.background)