function Mastercb(obj, event)
% master callback function
global comState screenPTR loopTrial
global Mstate

try
    n = get(comState.serialPortHandle, 'BytesAvailable');

    if n > 0
        inString = fread(comState.serialPortHandle, n);
        inString = char(inString');
    else
        return
    end
    
    % Remove terminator and display
    inString = inString(1:end-1);
    fprintf('COM: received from master "%s"\n', inString);
    
    delims = find(inString == ';');
    msgID = inString(1:delims(1)-1);  %Tells what button was pressed at master
    if strcmp(msgID,'M') || strcmp(msgID,'C') || strcmp(msgID,'S')
        paramstring = inString(delims(1):end); %list of parameters and their values
    elseif strcmp(msgID,'B')        
        modID = inString(delims(1)+1:delims(2)-1); %The stimulus module (e.g. 'grater')
        loopTrial = str2double(inString(delims(2)+1:delims(3)-1));
        paramstring = inString(delims(3):end); %list of parameters and their values
    else
        modID = inString(delims(1)+1:delims(2)-1); %The stimulus module (e.g. 'grater')
        paramstring = inString(delims(2):end); %list of parameters and their values
    end
    delims = find(paramstring == ';');
    
    switch msgID
        case 'M'  %Update sent info from "main" window
            for i = 1:length(delims)-1
                dumstr = paramstring(delims(i)+1:delims(i+1)-1);
                id = find(dumstr == '=');
                psymbol = dumstr(1:id-1);
                pval = dumstr(id+1:end);
                updateMstate(psymbol,pval)
            end
        case 'P'  %Update sent info from "param" window.
            configurePstate(modID)
            for i = 1:length(delims)-1
                dumstr = paramstring(delims(i)+1:delims(i+1)-1);
                id = find(dumstr == '=');
                psymbol = dumstr(1:id-1);
                pval = dumstr(id+1:end);
                updatePstate(psymbol, pval)
            end
        case 'B'  % Build stimulus: update Looper and buffer to video card.
            for i = 1:length(delims)-1
                dumstr = paramstring(delims(i)+1:delims(i+1)-1);
                id = find(dumstr == '=');
                psymbol = dumstr(1:id-1);
                pval = dumstr(id+1:end);
                updatePstate(psymbol, pval)
            end
            makeTexture(modID)
            makeSyncTexture
            %Commented because it doesn't
            %allow me to change parameters for different trials.
            %loop Trial = -1 signifies 'sample' stimulus, which is
            %necessary to stop shutter control.
            %'if' statement so that it only builds/buffers the random ensemble
            %on first trial. e.g. we want to reset the looper variables
            %(above) for variables like 'rseed', but not build the ensemble
            %all over again. 
            %if ~strcmp(modID,'FG') || loopTrial == 1 || loopTrial == -1
            %    makeTexture(modID)  
            %end
        case 'G'  % Go. Play stimulus and let master know when finished.
            playstimulus(modID)
            fwrite(comState.serialPortHandle, 'nextT~')
        case 'MON'  % Update monitor info.
            Mstate.monitor = modID;
            updateMonitor
        case 'C'  % Close display.
            Screen('Close')
            Screen('CloseAll');
            Priority(0);         
        case 'Q'  % Used by calibration.m at the Master (not part of 'Stimulator')
            paramstring = paramstring(2:end);            
            RGB = [str2double(paramstring(1:3)) str2double(paramstring(4:6)) ...
                str2double(paramstring(7:9))];
            Screen(screenPTR, 'FillRect', RGB)
            Screen(screenPTR, 'Flip');
        case 'S'  % Move shutter
            % Commented 170109 mmf, no slave Daq or shutter
            %eye = str2num(paramstring(delims(1)+1:delims(2)-1)); %setting of LE shutter
            %pos = str2num(paramstring(delims(2)+1:delims(3)-1)); %setting of RE shutter
            %moveShutter(eye,pos);
            %pause(2)
            disp('Mastercb WARNING: master asked to move shutter, but slave shutter capability disabled')    
    end
    if ~strcmp(msgID,'G')
        fwrite(comState.serialPortHandle, 'a')  %dummy so that Master knows it finished
    end
catch
    Screen('CloseAll');
    ShowCursor;
    msg = lasterror;
    msg.message
    msg.stack.file
    msg.stack.line
    fwrite(comState.serialPortHandle,'a')  %dummy so that Master knows it finished
end