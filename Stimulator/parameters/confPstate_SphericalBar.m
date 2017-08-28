function confPstate_SphericalBar
    % default parameters for the Spherical Bar stimulus
    % adapted from previous version by Onyekachi 'Kachi' Odoemene
    % (originally Ian Nauhaus)
    global Pstate
    
    sh = @(c) size(c,2);

    Pstate = struct;
    Pstate.type = 'SB';
    Pstate.param{1} = {'predelay', 'float', 10, 0, 'sec'};
    Pstate.param{sh(Pstate.param)+1} = {'stim_time', 'float', 300, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'postdelay', 'float', 10, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'BarThickness', 'int', 5, 0, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'BarOrient', 'int', 1, 0, ' 1=horz 0=vert'};
    Pstate.param{sh(Pstate.param)+1} = {'BarDirection', 'int', 1, 0, ' 1=fwd -1=rev'};
    Pstate.param{sh(Pstate.param)+1} = {'NumCycles', 'int', 10, 0, ''};
    Pstate.param{sh(Pstate.param)+1} = {'CheckSize', 'float', 10, 0, ' deg'};
    Pstate.param{sh(Pstate.param)+1} = {'FlickerRate', 'float', 6, 0, ' Hz'};
    Pstate.param{sh(Pstate.param)+1} = {'contrast', 'int', 100, 0, '%'};
    Pstate.param{sh(Pstate.param)+1} = {'TrialInterval', 'int', 10, 0, ' sec'};
    Pstate.param{sh(Pstate.param)+1} = {'eyeXLocation', 'float', 26.035, 0, ' cm (half monitor X)'};
    Pstate.param{sh(Pstate.param)+1} = {'eyeYLocation', 'float', 14.605, 0, ' cm (half monitor Y)'};
    Pstate.param{sh(Pstate.param)+1} = {'ScreenScaleFactor', 'int', 4, 0, ' x'};
    Pstate.param{sh(Pstate.param)+1} = {'sphereCorrectON', 'int', 1, 0, ' 1=on 0=off'};