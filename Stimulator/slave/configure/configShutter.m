function configShutter
    global daq shutterState

    % Commented 170109 mmf, no slave Daq or shutter
    %shutterState = 0;
    %DaqDConfigPort(daq, 1, 0);    
    %DaqDOut(daq, 1, 0); 
    disp('configShutter WARNING: slave shutter capability disabled')
