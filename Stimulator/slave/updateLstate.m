function updateLstate
    global Lstate GUIhandles
    Gh = GUIhandles;
    
    Lstate.reps = str2double(get(Gh.looper.repeats, 'string'));
    Lstate.rand = get(Gh.looper.randomflag, 'value');

    Lstate.param{1} = {[get(Gh.looper.symbol1, 'string')] ...
        [get(Gh.looper.valvec1, 'string')]};
    Lstate.param{2} = {[get(Gh.looper.symbol2, 'string')] ...
        [get(Gh.looper.valvec2, 'string')]};
    Lstate.param{3} = {[get(Gh.looper.symbol3, 'string')] ...
        [get(Gh.looper.valvec3, 'string')]};
    %Lstate.param{4} = {[get(Gh.looper.symbol4, 'string')] ... 
    %    [get(Gh.looper.valvec4, 'string')]};
    %Lstate.param{5} = {[get(Gh.looper.symbol5, 'string')] ... 
    %    [get(Gh.looper.valvec5, 'string')]};
    
    GUIhandles = Gh;