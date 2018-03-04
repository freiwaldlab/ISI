function saveTrialInfo(trialInfo)
    global trialno
    global pathBase prefixDate

    eval(['trialInfo' num2str(trialno) '=trialInfo;'])

    if ~exist(pathBase, 'dir')
        mkdir(pathBase);
        disp([mfilename ': Base path did not exist. Created [' pathBase '].']);
    end
    file_name = fullfile(pathBase, prefixDate, ...
        [prefixDate '_ExperimentParameters.mat']);
    save(file_name, ['trialInfo' num2str(trialno)], '-append');
    disp([mfilename ': Appended trialInfo to experiment parameters ' ...
        ' file [' file_name '].']);
    clear file_name