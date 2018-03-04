function refreshLooperView
    global Lstate GUIhandles

    if isfield(Lstate, 'reps')
        set(GUIhandles.looper.repeats, 'string', Lstate.reps);
    end
    if isfield(Lstate, 'rand')
        set(GUIhandles.looper.randomflag, 'value', Lstate.rand);
    end
    if isfield(Lstate, 'blanktog')
        set(GUIhandles.looper.blankflag, 'value', Lstate.blanktog);
    end
    if isfield(Lstate, 'blankper')
        set(GUIhandles.looper.blankPeriod, 'string', Lstate.blankper);
    end
    
    if isfield(Lstate, 'param')
        if numel(Lstate.param) > 1 || ~isempty(Lstate.param{:})
            for i = 1:length(Lstate.param)
                eval(['symhandle = GUIhandles.looper.symbol' num2str(i) ';']);
                eval(['valhandle = GUIhandles.looper.valvec' num2str(i) ';']);
                set(symhandle, 'string', Lstate.param{i}{1});
                set(valhandle, 'string', Lstate.param{i}{2});
            end
        end
    end
    
    if isfield(Lstate, 'formula')
        set(GUIhandles.looper.formula, 'string', Lstate.formula);
    end