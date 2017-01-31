function updateLstate
    global Lstate GUIhandles
    Gh = GUIhandles;
    
    Lstate.reps = str2double(get(Gh.looper.repeats, 'string'));
    Lstate.rand = get(Gh.looper.randomflag, 'value');

    Ldum{1} = {[get(Gh.looper.symbol1, 'string')] ...
        [get(Gh.looper.valvec1, 'string')]};
    Ldum{2} = {[get(Gh.looper.symbol2, 'string')] ...
        [get(Gh.looper.valvec2, 'string')]};
    Ldum{3} = {[get(Gh.looper.symbol3, 'string')] ...
        [get(Gh.looper.valvec3, 'string')]};
    %Ldum{4} = {[get(Gh.looper.symbol4, 'string')] ...
    %    [get(Gh.looper.valvec4, 'string')]};
    %Ldum{5} = {[get(Gh.looper.symbol5, 'string')] ...
    %    [get(Gh.looper.valvec5, 'string')]};

    % Purge any blank settings
    Lstate.param = cell(1, 1);
    k = 1;
    for i = 1:length(Ldum)
        if ~isempty(Ldum{i}{1})
            Lstate.param{k} = Ldum{i};        
            k = k + 1;
        end
    end

    Lstate.formula = get(Gh.looper.formula, 'string');
    
    GUIhandles = Gh;