function saveSyncInfo(syncInfo)
    global trialno
    global pathBase prefixDate

    eval(['syncInfo' num2str(trialno) '=syncInfo;'])

    if ~exist(pathBase, 'dir')
        mkdir(pathBase);
        disp([mfilename ': Base path did not exist. Created [' pathBase '].']);
    end
    file_name = fullfile(pathBase, prefixDate, ...
        [prefixDate '_ExperimentParameters.mat']);
    save(file_name, ['syncInfo' num2str(trialno)], '-append');
    disp([mfilename ': Appended syncInfo to experiment parameters ' ...
        ' file [' file_name '].']);
    clear file_name