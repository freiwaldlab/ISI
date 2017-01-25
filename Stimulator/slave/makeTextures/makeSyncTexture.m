function makeSyncTexture
    %write black/white sync to the offscreen
    global Mstate screenPTR screenNum 
    global Stxtr
    window = screenPTR;

    % %%% DEBUG XXX ***
    % Screen('Preference', 'SkipSyncTests', 1);
    % % Get the screen numbers
    % screens = Screen('Screens');
    % % Draw to the external screen if avaliable
    % screenNumber = max(screens);
    % screenNum = screenNumber;
    % % Open an on screen window
    % [window, ~] = Screen('OpenWindow', screenNumber, 128, [0 0 500 500]);
    % Mstate.screenXcm = 5;
    % Mstate.screenYcm = 5;
    
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