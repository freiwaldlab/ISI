function saveExptParams
    global Mstate Pstate Lstate looperInfo DataPath

    % Populate Analyzer construct with settings
    Analyzer.M = Mstate;
    Analyzer.P = Pstate;
    Analyzer.L = Lstate;
    Analyzer.loops = looperInfo;

    % Make sure destination directory exists and save the analyzer file
    title = [Mstate.anim '_' sprintf('u%s', Mstate.unit) '_' Mstate.expt];
    roots = parseString(DataPath, ';'); %parseString(Mstate.analyzerRoot,';');
    disp(['saveExptParams DEBUG: Saving analyzer file to main ' ...
        'experiment directory rather than analyzerRoot.'])
    for i = 1:length(roots)
        dd = [roots{i} filesep]; %[roots{i} filesep Mstate.anim];
        % Check if directory exists in case this is a new animal
        if(~exist(dd, 'dir'))
            mkdir(dd);
        end
        file_name = [dd filesep title '.analyzer'];
        disp(['saveExptParams: Saving analyzer file (' file_name ').'])
        save(file_name, 'Analyzer')
    end