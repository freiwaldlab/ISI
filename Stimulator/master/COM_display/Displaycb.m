function Displaycb(obj, event)
    % slave callback function
    global DcomState GUIhandles trialInfo

    n = get(DcomState.serialPortHandle, 'BytesAvailable');
    if n > 0
        inString = fread(DcomState.serialPortHandle, n);
        inString = char(inString');
    else
        return
    end

    % Remove terminator and display
    inString = inString(1:end-1);
    fprintf('COM from slave: \n%s\n', inString);

    % 'nextT' is the string sent after stimulus play is finished
    % If it just played a stimulus, and scanimage is not acquiring, then
    % run next trial...
    if (strcmp(inString, 'nextT') && ...
       ~get(GUIhandles.main.twophotonflag, 'value') && ...
       ~get(GUIhandles.main.intrinsicflag, 'value'))
        run2    
    end
    
    % If stimulus is an ImageBlock, receive order of image display.
    if (strfind(inString, 'SO;IB') == 1)
        inString = inString(1+6:end);
        trialInfo = strsplit(inString, ';');
        trialInfo = trialInfo(~cellfun('isempty', trialInfo)); 
    end