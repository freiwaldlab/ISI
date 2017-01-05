function configurePstate_ImageBlock
    global Pstate

    sh = @(c) size(c,2);
    
    Pstate = struct;
    Pstate.type = 'IB'; %%%% *** NEEDS TO BE CHANGED
    Pstate.param{1} =  {'delay_pre', 'float', 2, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'delay_post', 'float', 2, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'image_duration', 'float', 1, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'ori', 'int', 0, 0, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 600, 0, ' pixels'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 400, 0, ' pixels'};
    Pstate.param{sh(Pstate.param)+1} = {'x_size', 'float', 3, 1, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'y_size', 'float', 3, 1, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_zoom', 'int', 1, 0, ' x'};
    Pstate.param{sh(Pstate.param)+1} = {'y_zoom', 'int', 1, 0, ' x'};
    Pstate.param{sh(Pstate.param)+1} = {'interval', 'int', 1, 0, ' msec'};
    Pstate.param{sh(Pstate.param)+1} = {'order', 'int', 1, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};