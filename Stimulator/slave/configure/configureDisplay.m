function configureDisplay(varargin)
    global screenPTR
    close all
    window = screenPTR;

    max_priority = MaxPriority(window);
    % %Make sure priority is set to "real-time"  
    %Priority(5);
    % Set priority to 2, which appears to work
    %Priority(2);
    % Set maximum priority 
    Priority(max_priority);
    disp([mfilename ': screen priority set to ' num2str(max_priority) '.']);

    % Initialize stimulus parameter structures,
    % defaulting to Image Block mode
    configurePstate('IB')
    configureMstate

    configCom

    % Commented 170109 mmf, no slave Daq or shutter
    %configSync;
    %configShutter;

    screenconfig