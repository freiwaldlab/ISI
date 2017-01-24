function makeSyncTexture
    %write black/white sync to the offscreen
    global Mstate screenPTR screenNum 
    global Stxtr

    % Get pixel intensity values for white and black
    white = WhiteIndex(screenPTR);
    black = BlackIndex(screenPTR);

    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;

    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);

    % "high" state
    Stxtr(1) = Screen(screenPTR, 'MakeTexture', ...
        (white * ones(syncHpx, syncWpx)));
    % "low" state
    Stxtr(2) = Screen(screenPTR, 'MakeTexture', ...
        (black * ones(syncHpx, syncWpx)));