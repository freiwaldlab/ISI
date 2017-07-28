function confPstate_Mapper
    % default parameters for the Mapper stimulus
    global Pstate

    sh = @(c) size(c,2);
    
    Pstate = struct;
    Pstate.type = 'MP';
    Pstate.param{1} = {'ori', 'int', 0, 0, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 960, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 540, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'width', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'length', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'y_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};