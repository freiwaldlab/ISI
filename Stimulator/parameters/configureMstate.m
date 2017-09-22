function configureMstate
    global Mstate

    Mstate.anim = 'mittens';
    %Mstate.unit = '000';
    %Mstate.expt = '000';
    Mstate.hemi = 'left';
    
    % This should match the default value in Display
    Mstate.monitor = 'VPX';
    % Set distance of animal from screen (in cm)
    Mstate.screenDist = 30.5;
    % Set size of the screen sync (in cm)
    Mstate.syncSize = 2.0;

    % Set path for saving experimental parameters
    Mstate.analyzerRoot = 'D:\';

    % Set slave computer IP for communication
    Mstate.stimulusIDP = '192.168.1.101'; %'129.85.181.189';
    
    % Set running state
    Mstate.running = 0;
    
    % Set camera pixel size in um
    Mstate.cameraPxSize = 5.86;