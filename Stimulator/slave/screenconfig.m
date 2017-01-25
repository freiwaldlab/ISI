function screenconfig
    global screenPTR screenRes screenNum Mstate

    %screens = Screen('Screens');
    %screenNum = max(screens);
    screenNum = 0;
    screenRes = Screen('Resolution', screenNum);
    screenPTR = Screen('OpenWindow', screenNum);
    Screen(screenPTR, 'BlendFunction', GL_SRC_ALPHA, ...
        GL_ONE_MINUS_SRC_ALPHA);

    updateMonitor

    Screen('PixelSizes', screenPTR)
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);

    Mstate.refresh_rate = 1 / Screen('GetFlipInterval', screenPTR);

    SyncLoc = [0 0 syncWpx-1 syncHpx-1]';
    SyncPiece = [0 0 syncWpx-1 syncHpx-1]';

    Screen(screenPTR, 'FillRect', 128)
    Screen(screenPTR, 'Flip');
    wsync = Screen('MakeTexture', screenPTR, 0 * ones(syncHpx, syncWpx));
    Screen('DrawTexture', screenPTR, wsync, SyncPiece, SyncLoc);
    Screen(screenPTR, 'Flip');