function makeSyncTexture
    % Write black/white sync to the offscreen
    global Mstate screenPTR screenNum 
    global Stxtr
    window = screenPTR;
    
    % Get pixel intensity values for white and black
    white = WhiteIndex(window);
    black = BlackIndex(window);

    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);

    % "high" state
    Stxtr(1) = Screen('MakeTexture', window, ...
        (white * ones(syncHpx, syncWpx)));
    % "low" state
    Stxtr(2) = Screen('MakeTexture', window, ...
        (black * ones(syncHpx, syncWpx)));