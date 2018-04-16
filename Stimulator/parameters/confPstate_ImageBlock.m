function confPstate_ImageBlock
    % default parameters for the Image Block stimulus
    global Pstate

    sh = @(c) size(c,2);
    
    Pstate = struct;
    Pstate.type = 'IB';
    Pstate.param{1} = {'predelay', 'float', 2, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'postdelay', 'float', 2, 0, ...
        ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'image_duration', 'float', ...
        0.2, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'interval_duration', 'float', ...
        0.1, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'ori', 'int', 0, 0, 'deg'};
    Pstate.param{sh(Pstate.param)+1} = {'x_pos', 'int', 960, 0, ' px'};
    Pstate.param{sh(Pstate.param)+1} = {'y_pos', 'int', 540, 0, ' px'};
    Pstate.param{sh(Pstate.param)+1} = {'x_size', 'float', 10, 1, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'y_size', 'float', 10, 1, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'randomize', 'string', 'T', 0, ...
        ' (T or F)'};
    Pstate.param{sh(Pstate.param)+1} = {'background', 'int', 128, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'image_path', 'string', ...
        'C:\Dropbox\Stimuli\FullFOB3\', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'image_ext', 'string', ...
        'bmp', 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'contrast', 'int', 100, 0, '%'};
    Pstate.param{sh(Pstate.param)+1} = {'altazimuth', 'string', 'none', ...
        0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'stim_time', 'float', 44, 0, ...
        ' sec (auto)'}; 