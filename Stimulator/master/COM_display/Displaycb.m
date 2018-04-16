function Displaycb(obj, event)
    % slave callback function
    global DcomState GUIhandles trialInfo
    global nextStimState 
    
    n = get(DcomState.serialPortHandle, 'BytesAvailable');
    if n > 0
        inString = fread(DcomState.serialPortHandle, n);
        inString = char(inString');
    else
        return
    end

    % Remove terminator and display
    inString = inString(1:end-1);
    if ~strcmp(inString, 'nextStim')
        disp(['COM from slave: ' inString]);
    end
    
    % If image texture made, set total time based on number of images.
    if isequal(strfind(inString, 'MT;IB'), 1) || isequal(strfind(inString, 'MT;IR'), 1)
        inString = inString(1+6:end);
        trialInfo = strsplit(inString, ';');
        trialInfo = trialInfo(~cellfun('isempty', trialInfo));
        set(findobj('Tag', 'timetxt'), 'String', str2double(trialInfo{1}));
    end
    
    % If stimulus is image based, receive order of image display.
    if isequal(strfind(inString, 'SO;IB'), 1) || isequal(strfind(inString, 'SO;IR'), 1)
        inString = inString(1+6:end);
        trialInfo = strsplit(inString, ';');
        trialInfo = trialInfo(~cellfun('isempty', trialInfo));
    end
    
    % 'nextT' is the string sent after stimulus play is finished
    % If it just played a stimulus, and scanimage is not acquiring, then
    % run next trial...
    if strcmp(inString, 'nextT')
        if (~get(GUIhandles.main.twophotonflag, 'value') && ...
                ~get(GUIhandles.main.intrinsicflag, 'value'))
            runExpt
        end
    end
    
    % 'nextStim' is the string sent after each individual stimulus in a
    % block is presented in case special handling is needed (e.g. for
    % ImageRandomizer)
    if strcmp(inString, 'nextStim')
       nextStimState = 'playing';
    end
    if strcmp(inString, 'endStim')
       nextStimState = 'finished';
    end