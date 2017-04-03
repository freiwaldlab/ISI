function [flag, dd] = checkforOverwrite
    global Mstate GUIhandles DataPath
    animal = get(findobj('Tag', 'animaltxt'), 'string');
    unit = get(findobj('Tag', 'unittxt'), 'string');
    expt = get(findobj('Tag', 'expttxt'), 'string');
    datadir = get(findobj('Tag', 'datatxt'), 'string');

    dd = [datadir filesep lower(animal) filesep 'u' unit '_' expt];

    flag = 0;

    % Increment experiment number until no matching data directory exists
    while exist(dd, 'dir')
        disp(['checkforOverwrite: Data directory exists, ' ...
            'incrementing experiment number.'])
        expt = sprintf('%03d', str2double(expt) + 1);
        Mstate.expt = expt;
        set(findobj('Tag', 'expttxt'), 'string', expt)
        set(GUIhandles.main.exptcb, 'string', expt)
        UpdateACQExptName
        
        dd = [datadir filesep lower(animal) filesep 'u' unit '_' expt];
    end