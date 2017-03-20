function playimageblock
    global Mstate screenPTR screenNum comState
    global Gtxtr TDim % from makeImageBlockTexture
    global Stxtr % from makeSyncTexture
    syncHigh = Stxtr(1);
    syncLow = Stxtr(2);

    P = getParamStruct;
    window = screenPTR;
    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);
    
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
        stimWpx = round(resXpxpercm * stimWcm);
        stimHcm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
        stimHpx = round(resYpxpercm * stimHcm);
    else
        stimWcm = 2 * Mstate.screenDist * tan((P.x_size / 2) * (pi / 180));
        stimWpx = round(resXpxpercm * stimWcm);
        stimHcm = 2 * Mstate.screenDist * tan((P.y_size / 2) * (pi / 180));
        stimHpx = round(resYpxpercm * stimHcm);
    end
    
    % Calculate the pixel range of the stimulus
    %   NOTE: Truncating to the screen size messes things up.
    imWpx = TDim(1);
    imHpx = TDim(2);
    rngXpx = [(P.x_pos - floor(stimWpx / 2) + 1) ...
        (P.x_pos + ceil(stimWpx / 2))];
    rngYpx = [(P.y_pos - floor(stimHpx / 2) + 1) ...
        (P.y_pos + ceil(stimHpx / 2))];
    % Calculate the sync and stimulus location details
    syncPos = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    syncPiece = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    stimPos = [rngXpx(1) rngYpx(1) rngXpx(2) rngYpx(2)]';
    stimPiece = [0 0 imWpx imHpx]';
    
    % Make a list of all frames and another with random ordering
    imNum = size(Gtxtr, 2);
    imList = (1:imNum)';
    % Determine the order in which images will be presented
    if strcmpi(P.randomize, 'T')
        disp('playimageblock: Image presentation will be RANDOMLY ordered.');
        imList = imList(randperm(size(imList, 1)))';
    elseif strcmpi(P.randomize, 'F')
        disp('playimageblock: Image presentation will be SERIALLY ordered.');
    else
        disp(['playimageblock WARNING: Setting for randomization ' ...
            'incorrect. Assuming random ordering as default.']);
        disp('playimageblock: Image presentation will be RANDOMLY ordered.');
        imList = imList(randperm(size(imList, 1)))';
    end
    % Communicate order of image presentation to master
    imPath = P.image_path;
    imListStr = strjoin(string(imList), ',');
    strcat('IBorder;', imPath, ';', imListStr, ';~')
    fwrite(comState.serialPortHandle, 'x')
    
    % Pre-delay
    % Draw "high" sync state for first half of pre-delay to indicate 
    % beginning of new block
    Screen('DrawTexture', window, syncHigh, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);
    % Draw "low" sync state during rest of pre-delay
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.predelay / 2);
    
    % Play stimulus by drawing pre-generated textures to the screen
    for imn = imList
        % Simultaneously draw "high" sync and image to the screen
        %   Unless otherwise specified PTB will draw the texture 
        %   full size in the center of the screen
        Screen('DrawTextures', window, [syncHigh Gtxtr(imn)], ...
           [syncPiece stimPiece], [syncPos stimPos], [0 P.ori]);
        % Flip to the window
        Screen('Flip', window);
        % Wait for specified per-image duration
        WaitSecs(P.image_duration);
        % Now simultaneously draw "low sync" and blank the screen 
        % with the background
        Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
        % Flip to the window
        Screen('Flip', window);
        % Wait for specified inter-image interval unless this is the 
        % last image
        if imn ~= imList(end)
            WaitSecs(P.interval_duration);
        end
    end
    clear imn
    
    % Post-delay
    % Draw "low" sync state for duration of post-delay block
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.postdelay);