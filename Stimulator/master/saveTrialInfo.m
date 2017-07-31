function saveTrialInfo(trialInfo)
    global Mstate trialno DataPath

    eval(['trialInfo' num2str(trialno) '=trialInfo;'])

    % Make sure destination directory exists and save the analyzer file
    title = [Mstate.anim '_' sprintf('u%s', Mstate.unit) '_' Mstate.expt];
    roots = parseString(DataPath, ';');
    for i = 1:length(roots)
        dd = [roots{i} filesep];
        % Check if directory exists in case this is a new animal
        if(~exist(dd, 'dir'))
            mkdir(dd);
        end
        file_name = [dd filesep title '.analyzer'];
        disp([mfilename ': Appending trialInfo to .analyzer file (' ...
            file_name ').'])
        save(file_name, ['trialInfo' num2str(trialno)], '-append')
    end