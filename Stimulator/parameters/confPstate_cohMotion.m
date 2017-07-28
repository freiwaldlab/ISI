function confPstate_cohMotion
    % default parameters for the Coherent Motion (periodic random dot) stimulus
    global Pstate
    
    sh = @(c) size(c,2);
    
    Pstate = struct;
    Pstate.type = 'CM';
    
    Pstate.param{1} = {'predelay', 'float', 2 0 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'postdelay', 'float', 2, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'stim_time', 'float', 1, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 960, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 540, 0, 'px'};
    Pstate.param{sh(Pstate.param)+1} = {'x_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'y_size', 'float', 3, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'mask_type', 'string', 'none', 0, 'none, disc'};
    Pstate.param{sh(Pstate.param)+1} = {'mask_radius', 'float', 6, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'ori', 'int', 0, 1, 'deg'}; 
    Pstate.param{sh(Pstate.param)+1} = {'dotDensity', 'float', 100, 1, 'dots/(deg^2 s)'};
    Pstate.param{sh(Pstate.param)+1} = {'sizeDots', 'float', 0.2, 1, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'speedDots', 'float', 5, 1, 'deg/s'};
    Pstate.param{sh(Pstate.param)+1} = {'dotLifetime', 'int', 0, 1, 'frames, 0 inf'};
    Pstate.param{sh(Pstate.param)+1} = {'dotCoherence', 'int', 100, 1, '%'};
    Pstate.param{sh(Pstate.param)+1} = {'dotType', 'int', 0, 1, 'sq, circ'};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'redgun', 'int', 255, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'greengun', 'int', 255, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'bluegun', 'int', 255, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'contrast', 'float', 100, 0, '%'};