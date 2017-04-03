function updateLstate
    global Lstate GUIhandles

    Lstate.reps = str2double(get(GUIhandles.looper.repeats, 'string'));
    Lstate.rand = get(GUIhandles.looper.randomflag, 'value');

    Ldum{1} = {[get(GUIhandles.looper.symbol1, 'string')] ...
        [get(GUIhandles.looper.valvec1, 'string')]};
    Ldum{2} = {[get(GUIhandles.looper.symbol2, 'string')] ...
        [get(GUIhandles.looper.valvec2, 'string')]};
    Ldum{3} = {[get(GUIhandles.looper.symbol3, 'string')] ...
        [get(GUIhandles.looper.valvec3, 'string')]};

    % Purge any blank settings
    Lstate.param = cell(1, 1);
    k = 1;
    for i = 1:length(Ldum)
        if ~isempty(Ldum{i}{1})
            Lstate.param{k} = Ldum{i};
            k = k + 1;
        end
    end

    Lstate.formula = get(GUIhandles.looper.formula, 'string');