function UpdateACQExptName
    global GUIhandles Mstate DataPath
    %global ACQserial

    ScanImageBit = get(GUIhandles.main.twophotonflag, 'value');
    ISIBit = get(GUIhandles.main.intrinsicflag, 'value');

% set(0,'DefaultTextFontName','helvetica','DefaultTextFontAngle','normal','DefaultTextColor',[0 0 0])
% button = questdlg(sprintf('Are you sure you want to save the data\nand advance to the next experiment?'));
% set(0,'DefaultTextFontName','helvetica','DefaultTextFontAngle','oblique','DefaultTextColor',[1 1 0])

    if ScanImageBit
        msg = [Mstate.anim '_u' Mstate.unit '_' Mstate.expt];
        Stimulus_localCallback(msg);
    end
    if ISIBit
        % Send expt info to imager
        sendtoImager(['U ' Mstate.unit]);  
        sendtoImager(['E ' Mstate.expt]); 
        sendtoImager(['A ' Mstate.anim]);
    end
    
    %trial = str2double(cmd(3:end));
    animal = get(findobj('Tag', 'animaltxt'), 'string');
    unit = get(findobj('Tag', 'unittxt'), 'string');
    expt = get(findobj('Tag', 'expttxt'), 'string');
    datadir = get(findobj('Tag', 'datatxt'), 'string');
    tag = get(findobj('Tag', 'tagtxt'), 'string');
    DataPath = [datadir filesep lower(animal) filesep 'u' unit '_' expt];