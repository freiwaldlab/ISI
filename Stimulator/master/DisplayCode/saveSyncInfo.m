function saveSyncInfo(syncInfo)
    global Mstate trialno DataPath

    eval(['syncInfo' num2str(trialno) '=syncInfo;'])
    %%clear syncInfo commented 170205

    % Make sure destination directory exists and save the analyzer file
    title = [Mstate.anim '_' sprintf('u%s',Mstate.unit) '_' Mstate.expt];
    roots = parseString(DataPath, ';'); %parseString(Mstate.analyzerRoot,';');
    disp(['saveSyncInfo DEBUG: Appending to analyzer file in main ' ... 
        'experiment directory rather than analyzerRoot.'])
    for i = 1:length(roots)
        dd = [roots{i} filesep]; %[roots{i} filesep Mstate.anim];
        % Check if directory exists in case this is a new animal
        if(~exist(dd, 'dir'))
            mkdir(dd);
        end
        file_name = [dd filesep title '.analyzer'];
        disp(['saveSyncInfo: Appending syncInfo to .analyzer file (' ...
            file_name ').'])
        save(file_name, ['syncInfo' num2str(trialno)], '-append')
    end
