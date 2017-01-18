function moveShutter(eye, pos)
    global daq shutterState

    % Commented 170109 mmf, no slave Daq or shutter
    %shutterState = bitset(shutterState, eye, 1 - pos);
    %disp(shutterState)
    %DaqDOut(daq, 1, shutterState);
    disp('moveShutter WARNING: slave shutter capability disabled')
