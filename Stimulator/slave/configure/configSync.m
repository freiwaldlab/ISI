function configSync
    global daq

    % Commented 170109 mmf, no slave Daq or shutter
    %daq = DaqDeviceIndex;
    %if ~isempty(daq)
    %    DaqDConfigPort(daq, 0, 0);
    %    DaqDOut(daq, 0, 0);
    %else
    %    'Daq device does not appear to be connected'
    %end
    disp('configSync WARNING: slave shutter capability disabled')