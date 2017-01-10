function configureDisplay(varargin)
    close all

    Priority(5);  %Make sure priority is set to "real-time"  

    %priorityLevel=MaxPriority(w);
    %Priority(priorityLevel);

    configurePstate('PG') %Use grater as the default when opening
    configureMstate

    configCom(varargin);

    % Commented 170109 mmf, no slave Daq or shutter
    %configSync;
    %configShutter;

    screenconfig;
