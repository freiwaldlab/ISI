function confPstate_flashGrater
    % default parameters for the Flash Grater stimulus
    global Pstate

    sh = @(c) size(c,2);
    
    Pstate = struct; 
    Pstate.type = 'FG';

    Pstate.param{1} = {'predelay', 'float', 2, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'postdelay', 'float', 2, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'stim_time', 'float', 1, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 960, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 540, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'x_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'y_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'mask_type', 'string', 'none', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'mask_radius', 'float', 6, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'y_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'contrast', 'float', 100, 0, '%'};
    Pstate.param{sh(Pstate.param)+1} = {'ori', 'int', 0, 0, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'h_per', 'int', 3, 0, 'frames'};
    Pstate.param{sh(Pstate.param)+1} = {'n_ori', 'int', 8, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'n_phase', 'int', 4, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'min_sf', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'max_sf', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'n_sfreq', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'sf_domain', 'string', 'log', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'separable', 'int', 0, 0, 'bit'};
    Pstate.param{sh(Pstate.param)+1} = {'st_profile', 'string', 'sin', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'s_profile', 'string', 'sin', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'s_duty', 'float', 0.5, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'redgain', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'greengain', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'bluegain', 'float', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'redbase', 'float', 0.5, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'greenbase', 'float', 0.5, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'bluebase', 'float', 0.5, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'colorspace', 'string', 'gray', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'FourierBit', 'int', 0, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'rseed', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'blankProb', 'float', 0, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'eye_bit', 'int', 0, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'Leye_bit', 'int', 1, 0, ''};
    Pstate.param{38} = {'Reye_bit', 'int' 1 0 ''};