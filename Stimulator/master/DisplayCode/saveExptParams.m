function saveExptParams
    global Mstate Pstate Lstate looperInfo
    global pathBase prefixDate

    Analyzer.M = Mstate;
    Analyzer.P = Pstate;
    Analyzer.L = Lstate;
    Analyzer.loops = looperInfo;

    if ~exist(pathBase, 'dir')
        mkdir(pathBase);
        disp([mfilename ': Base path did not exist. Created [' ...
            pathBase '].']);
    end
    file_name = fullfile(pathBase, prefixDate, ...
        [prefixDate '_ExperimentParameters.mat']);
    disp([mfilename ': Saved experiment parameters [' file_name '].']);
    save(file_name, 'Analyzer');
    clear file_name