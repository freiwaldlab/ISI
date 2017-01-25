function Stimulator
    % Initialize stimulus parameter structures, 
    % defaulting to Image Block mode
    configurePstate('IB')
    configureMstate
    configureLstate

    % Set up master-slave communication
    configDisplayCom

    % NI USB input for ISI acquisition timing from frame grabber
    configSyncInput  

    %configEyeShutter

    % Open GUIs
    MainWindow
    Looper 
    paramSelect