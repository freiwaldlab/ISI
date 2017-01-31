function refreshLooperView
    global Lstate GUIhandles
    Gh = GUIhandles;
    
    set(Gh.looper.repeats, 'string', Lstate.reps)
    set(Gh.looper.randomflag, 'value', Lstate.rand)
    set(Gh.looper.formula, 'string', Lstate.formula)
    for i = 1:length(Lstate.param)
        eval(['symhandle = Gh.looper.symbol' num2str(i) ';'])
        eval(['valhandle = Gh.looper.valvec' num2str(i) ';'])
        set(symhandle, 'string', Lstate.param{i}{1})
        set(valhandle, 'string', Lstate.param{i}{2})
    end
    
    GUIhandles = Gh;