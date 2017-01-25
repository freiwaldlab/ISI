function confPstate_ImageBlock
    global Pstate

    sh = @(c) size(c,2);
    
    Pstate = struct;
    Pstate.type = 'IB';
    Pstate.param{1} =  {'delay_pre', 'float', 2, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'delay_post', 'float', 2, 0, ...
        ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'image_duration', 'float', 1, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'interval_duration', 'float', 1, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'ori', 'int', 0, 0, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 600, 0, ' px'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 600, 0, ' px'};
    Pstate.param{sh(Pstate.param)+1} = {'x_size', 'float', 10, 1, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'y_size', 'float', 10, 1, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'randomize', 'string', 'T', 0, ...
        ' (T or F)'};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'image_path', 'string', ...
        'C:\Dropbox\Stimuli\FullFOB3\', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'image_ext', 'string', ...
        'bmp', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'contrast', 'int', 100, 0, ' %'};
    Pstate.param{sh(Pstate.param)+1} = {'altazimuth', 'string', 'none', ...
        0, ''};