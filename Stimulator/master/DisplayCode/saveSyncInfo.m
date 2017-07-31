function saveSyncInfo(syncInfo)
    global Mstate trialno DataPath

    eval(['syncInfo' num2str(trialno) '=syncInfo;'])

    % Make sure destination directory exists and save the analyzer file
    title = [Mstate.anim '_' sprintf('u%s', Mstate.unit) '_' Mstate.expt];
    roots = parseString(DataPath, ';'); %parseString(Mstate.analyzerRoot,';');
    for i = 1:length(roots)
        dd = [roots{i} filesep]; %[roots{i} filesep Mstate.anim];
        % Check if directory exists in case this is a new animal
        if(~exist(dd, 'dir'))
            mkdir(dd);
        end
        file_name = [dd filesep title '.analyzer'];
        disp([mfilename ': Appending syncInfo to .analyzer file (' ...
            file_name ').']);
        save(file_name, ['syncInfo' num2str(trialno)], '-append');
    end