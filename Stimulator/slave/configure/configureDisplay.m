function configureDisplay(varargin)
    close all

    % %Make sure priority is set to "real-time"  
    %Priority(5);
    % Set priority to 2 for now, because it appears to work
    Priority(2);

    %priorityLevel=MaxPriority(w);
    %Priority(priorityLevel);

    configurePstate('PG') %Use grater as the default when opening
    configureMstate

    configCom(varargin);

    % Commented 170109 mmf, no slave Daq or shutter
    %configSync;
    %configShutter;

    screenconfig;
