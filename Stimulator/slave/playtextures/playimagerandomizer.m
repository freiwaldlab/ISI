function playimagerandomizer
    global Mstate screenPTR screenNum comState
    global Gtxtr TDim  % from makeImageRandomizerTexture
    global Stxtr  % from makeSyncTexture
    global nextPlay
    nextPlay = 'stop';
    syncHigh = Stxtr(1);
    syncLow = Stxtr(2);
    P = getParamStruct;
    window = screenPTR;
    
    screenRes = Screen('Resolution', screenNum);
    resXpxpercm = screenRes.width / Mstate.screenXcm;
    resYpxpercm = screenRes.height / Mstate.screenYcm;
    syncWpx = round(resXpxpercm * Mstate.syncSize);
    syncHpx = round(resYpxpercm * Mstate.syncSize);
    %ifi = Screen('GetFlipInterval', window);
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = (white + black) / 2;
    inc = white - grey;
    
    if strcmp(P.altazimuth, 'none')
        % Assumes curved screen (projects flat)
        stimWcm = 2 * pi * Mstate.screenDist * (P.x_size / 360);
        stimWpx = round(resXpxpercm * stimWcm);
        stimHcm = 2 * pi * Mstate.screenDist * (P.y_size / 360);
        stimHpx = round(resYpxpercm * stimHcm);
    else
        % Assumes flat screen (projects spherical)
        stimWcm = 2 * Mstate.screenDist * tan((P.x_size / 2) * (pi / 180));
        stimWpx = round(resXpxpercm * stimWcm);
        stimHcm = 2 * Mstate.screenDist * tan((P.y_size / 2) * (pi / 180));
        stimHpx = round(resYpxpercm * stimHcm);
    end
    
    imWpx = TDim(1);
    imHpx = TDim(2);
    rngXpx = [(P.x_pos - floor(stimWpx / 2) + 1) ...
        (P.x_pos + ceil(stimWpx / 2))];
    rngYpx = [(P.y_pos - floor(stimHpx / 2) + 1) ...
        (P.y_pos + ceil(stimHpx / 2))];
    syncPos = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    syncPiece = [0 0 (syncWpx - 1) (syncHpx - 1)]';
    stimPos = [rngXpx(1) rngYpx(1) rngXpx(2) rngYpx(2)]';
    stimPiece = [0 0 imWpx imHpx]';
    
    % Make a list of all frames and another with random ordering
    imNum = size(Gtxtr, 2);
    imList = (1:imNum)';
    
    % Determine the order in which images will be presented
    if strcmpi(P.randomize, 'T')
        disp([mfilename ': Image presentation will be RANDOMLY ordered.']);
        imList = imList(randperm(size(imList, 1)))';
    elseif strcmpi(P.randomize, 'F')
        disp([mfilename ': Image presentation will be SERIALLY ordered.']);
    else
        warning([mfilename ': Setting for randomization ' ...
            'incorrect. Assuming random ordering as default.']);
        disp([mfilename ': Image presentation will be RANDOMLY ordered.']);
        imList = imList(randperm(size(imList, 1)))';
    end
    
    % Communicate order of image presentation to master
    imPath = P.image_path;
    imListStr = sprintf('%.0f,', imList);
    imListStr = imListStr(1:end-1);
    msg = strcat('SO;IB;', imPath, ';', imListStr, ';~');
    fwrite(comState.serialPortHandle, msg);
    
    % Set screen to background
    Screen('FillRect', window, P.background);
    Screen('Flip', window);

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
    
    pathts = 'C:\ISI_troubleshooting\';
    % Play stimulus by drawing pre-generated textures to the screen
    for imn = imList
        [inmem_M, inmem_X, inmem_C] = inmem;
        [memory_user, memory_sys] = memory;
        memory_sys.PhysicalMemory
        memory_sys.SystemMemory
        save_path = fullfile(pathts, ['ImageRandomizer' '_im_' ...
            sprintf('%05d', imn)]);
        save_path
        save(save_path, 'inmem_M', 'inmem_X', 'inmem_C', ...
            'memory_user', 'memory_sys', '-v6');
        nextPlay = 'stop';
        disp([mfilename ': ' num2str(imn) ' ' nextPlay])
        while ~strcmpi(nextPlay, 'go')
            %disp([mfilename ': serialPortHandle.status ' comState.serialPortHandle.status])
            %disp([mfilename ': serialPortHandle.ReadAsyncMode ' comState.serialPortHandle.ReadAsyncMode])
            %disp([mfilename ': BytesAvailableFcn ' func2str(comState.serialPortHandle.BytesAvailableFcn)])
            %disp([mfilename ': BytesAvailableFcnMode ' comState.serialPortHandle.BytesAvailableFcnMode])
            %disp([mfilename ': TransferStatus' comState.serialPortHandle.TransferStatus])
            n = get(comState.serialPortHandle, 'BytesAvailable');
            if n > 6
                inString = fread(comState.serialPortHandle, n);
                inString = char(inString');
                %disp([mfilename ' : stuff received ' inString]);
                if strcmpi(inString, 'goplay~')
                    nextPlay = 'go';
                elseif strcmpi(inString, 'gohome~')
                    nextPlay = 'stop';
                    %disp([mfilename ': ' num2str(imn) ' ' nextPlay])
                    return
                end
            end
        end
        disp([mfilename ': ' num2str(imn) ' ' nextPlay])
        msg = 'nextStim~';
        fwrite(comState.serialPortHandle, msg);
        WaitSecs(P.interval_duration / 2);
        %disp([mfilename ': wrote to master, ' msg])
        % Simultaneously draw "high" sync and image to the screen
        %   Unless otherwise specified PTB will draw the texture 
        %   full size in the center of the screen
        Screen('DrawTextures', window, [Gtxtr(imn) syncHigh], ...
           [stimPiece syncPiece], [stimPos syncPos], [P.ori 0]);
        Screen('Flip', window);
        WaitSecs(P.image_duration);
        Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
        Screen('Flip', window);
        % Wait for specified inter-image interval unless this is the 
        % last image
        %if imn ~= imList(end)
        WaitSecs(P.interval_duration / 2);
        %end
        flushinput(comState.serialPortHandle);
    end
    clear imn
    msg = 'endStim~';
    fwrite(comState.serialPortHandle, msg);
    
    % Post-delay
    % Draw "low" sync state for duration of post-delay block
    Screen('DrawTexture', window, syncLow, syncPiece, syncPos);
    Screen('Flip', window);
    WaitSecs(P.postdelay);