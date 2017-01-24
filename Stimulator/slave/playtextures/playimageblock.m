function playimageblock
    global Mstate screenPTR screenNum
    global Gtxtr TDim % from makeImageBlockTexture
    global Stxtr % from makeSyncTexture
    
    P = getParamStruct;
    window = screenPTR;
    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);
    
    % % Get the size of the on screen window
    % [screenXpx, screenYpx] = Screen('WindowSize', window);
    % % Get the centre coordinate of the window
    % [screenCenterX, screenCenterY] = RectCenter(windowRect);
    % % Query the frame duration
    % ifi = Screen('GetFlipInterval', window);

    % Define black and white
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = white / 2;
    inc = white - grey;

    % Calculate stimulus parameters assuming the screen is slightly curved
    if strcmp(P.altazimuth, 'none')
        stimWcm = 2 * pi * Mstate.screenDist * (P.x_size / 360);
        stimWpx = round(stimWcm * resXpxpercm);
        stimHcm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
        stimHpx = round(stimHcm * resYpxpercm);
    else
        stimWpx = 2 * Mstate.screenDist * tan((P.x_size / 2) * (pi / 180));
        stimWpx = round(stimWpx * resXpxpercm);
        stimHpx = 2 * Mstate.screenDist * tan((P.y_size / 2) * (pi / 180));
        stimHpx = round(stimHpx * resYpxpercm);
    end
    
    % NOTE: Truncating these things to the screen size messes things up.
    rangeXpx = [(P.x_pos - floor(stimWpx / 2) + 1) ...
        (P.x_pos + ceil(stimWpx / 2))];
    rangeYpx = [(P.y_pos - floor(stimHpx / 2) + 1) ...
        (P.y_pos + ceil(stimHpx / 2))];
    
    % Calculate the sync and stimulus location details
    syncPos = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    syncPiece = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    stimPos = [rangeXpx(1) rangeYpx(1) rangeXpx(2) rangeYpx(2)]';
    stimPiece = [0 0 (TDim(2) - 1) (TDim(1) - 1)]';
    
    % Make a list of all frames and another with random ordering
    imList = (1:imNum)';
    imListRand = imList(randperm(size(imList, 1)))';
    
    %%% XXX *** TODO add parameter for random vs. ordered
    
    % Pre-delay
    % Draw "high" sync state quickly to indicate beginning of new block
    Screen('DrawTexture', window, Stxtr(1), syncPiece, syncPos);
    Screen(window, 'Flip');
    % Draw "low" sync state during rest of pre-delay
    Screen('DrawTexture', window, Stxtr(2), syncPiece, syncPos);
    Screen(window, 'Flip');
    WaitSecs(P.delay_pre);
    
    % Play stimulus by drawing pre-generated textures to the screen
    for imn = imListRand
        % Simultaneously draw "high" sync and image to the screen
        %   Unless otherwise specified PTB will draw the texture 
        %   full size in the center of the screen
        Screen('FillRect', window, P.background);
        Screen('DrawTexture', window, [Stxtr(1) Gtxtr(1)], ...
            [syncPiece stimPiece], [syncPos stimPos]);
        % Flip to the window
        Screen('Flip', window);
        % Wait for specified per-image duration
        WaitSecs(P.image_duration);
        % Now simultaneously draw "low sync" and blank the screen 
        % with the background
        Screen('FillRect', window, P.background);
        Screen('DrawTexture', window, Stxtr(2), syncPiece, syncPos);
        % Flip to the window
        Screen('Flip', window);
        if imn ~= imListRand(end)
            % Wait for specified inter-image interval
            WaitSecs(P.interval_duration);
        end
    end
    clear imn
    
    % Post-delay
    % Draw "low" sync state for duration of post-delay block
    Screen('DrawTexture', window, Stxtr(2), syncPiece, syncPos);
    Screen(window, 'Flip');
    WaitSecs(P.delay_post);