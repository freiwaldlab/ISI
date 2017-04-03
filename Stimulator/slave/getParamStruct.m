function P = getParamStruct
    global Pstate

    for i = 1:length(Pstate.param)
        eval(['P.' Pstate.param{i}{1} '= Pstate.param{i}{3} ;'])
    end