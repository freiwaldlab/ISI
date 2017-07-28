function confPstate_Rain
    % default parameters for the Rain stimulus
    global Pstate
    
    sh = @(c) size(c,2);
    
    Pstate = struct;
    Pstate.type = 'RD';
    Pstate.param{1} = {'predelay', 'float', 2, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'postdelay', 'float', 2, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'stim_time', 'float', 1, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 960, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 540, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'x_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'y_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'y_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'contrast', 'float', 100, 0, '%'};
    Pstate.param{sh(Pstate.param)+1} = {'ori', 'int', 0, 0, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'n_ori', 'int', 8, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'h_per', 'int', 3, 0, 'frames'};
    Pstate.param{sh(Pstate.param)+1} = {'Nx', 'int', 10, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'Ny', 'int', 10, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'gridType', 'string', 'Cartesian', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'speed', 'float', 0, 0, 'deg/frame'};
    Pstate.param{sh(Pstate.param)+1} = {'barWidth', 'float', 1, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'barLength', 'float', 1, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'bw_bit', 'int', 2, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'redgain', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'greengain', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'bluegain', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'redbase', 'float', 0.5, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'greenbase', 'float', 0.5, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'bluebase', 'float', 0.5, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'colorspace', 'string', 'gray', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'Ndrops', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'rseed', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'eye_bit', 'int', 0, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'Leye_bit', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'Reye_bit', 'int', 1, 0, ''};