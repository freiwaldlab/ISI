function confPstate_Noise
    % default parameters for the Noise stimulus
    global Pstate
    
    sh = @(c) size(c,2);
    
    Pstate = struct;
    Pstate.type = 'FN';
    Pstate.param{1} = {'predelay', 'float', 2, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'postdelay', 'float', 2, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'stim_time', 'float', 1, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 960, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 540, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'x_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'y_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'y_zoom', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'h_per', 'int', 1, 0, 'frames'};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'contrast', 'float', 100, 0, '%'};
    Pstate.param{sh(Pstate.param)+1} = {'tlp_cutoff', 'float', 30, 1, 'cyc/sec'};
    Pstate.param{sh(Pstate.param)+1} = {'thp_cutoff', 'float', 0, 1, 'cyc/sec'};
    Pstate.param{sh(Pstate.param)+1} = {'freq_decay', 'float', 1, 1, 'cm/cycle'};
    Pstate.param{sh(Pstate.param)+1} = {'rseed', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'tAmp_profile', 'string', 'none', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'tAmp_period', 'int', 20, 0, 'frames'};
    Pstate.param{sh(Pstate.param)+1} = {'eye_bit', 'int', 0, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'Leye_bit', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'Reye_bit', 'int', 1, 0, ''};