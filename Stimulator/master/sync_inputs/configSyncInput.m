function configSyncInput
    global analogIN

    % Check to be sure a DAQ board exists before trying to interact with it
    have_ni = 0;
    devs = daq.getDevices;
    for dn = 1:length(devs)
        if strcmp(devs(dn).Vendor.ID, 'ni')
            have_ni = 1;
            ni_dev_id = devs(dn).ID;
        end
    end
    % Establish connection with DAQ board
    if have_ni
        analogIN = daq.createSession('ni');
        addAnalogInputChannel(analogIN, ni_dev_id, 0:1, 'Voltage');
        % Rate determined by maximum on device/number of channels
        analogIN.Rate = 5000;
        analogIN.IsContinuous = true;
        disp('configSyncInput: Configured DAQ analogIN.')
    end
    if ~have_ni || isempty(analogIN)
        disp('configSyncInput ERROR: Could not find NI device.')
    end