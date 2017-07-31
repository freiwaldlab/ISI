function configSyncInput
    global analogIN daqOUTLED daqOUT2p daqOUTtrig daqOUTIOI

    % Check to be sure a DAQ board exists before trying to interact with it
    analogIN_devid = [];
    analogIN_desc = 'USB-6000';
    daqOUT_devid = [];
    daqOUT_desc = 'USB-6001';
    devs = daq.getDevices;
    for dn = 1:length(devs)
        if strcmp(devs(dn).Vendor.ID, 'ni') && ...
                ~isempty(strfind(devs(dn).Description, analogIN_desc))
            analogIN_devid = devs(dn).ID;
        end
        if strcmp(devs(dn).Vendor.ID, 'ni') && ...
                ~isempty(strfind(devs(dn).Description, daqOUT_desc))
            daqOUT_devid = devs(dn).ID;
        end
    end
    % Establish connection with DAQ board
    if ~isempty(analogIN_devid)
        analogIN = daq.createSession('ni');
        addAnalogInputChannel(analogIN, analogIN_devid, 0:4, 'Voltage');
        %0: photodiode, 1: strobe, 2: trigger copy, 3: audio copy, 4:
        %start/stop IOI ttl copy
        % Rate determined by maximum on device/number of channels
        analogIN.Rate = 2000;
        analogIN.IsContinuous = true;
        disp([mfilename ': Configured DAQ analog input.']);
    end
    if ~isempty(daqOUT_devid)
        daqOUTLED = daq.createSession('ni');
        daqOUT2p = daq.createSession('ni');
        daqOUTIOI = daq.createSession('ni');
        daqOUTtrig = daq.createSession('ni');
        % % % SET UP DAQ OUT
        addDigitalChannel(daqOUTLED, daqOUT_devid, 'Port0/Line0', 'OutputOnly');
        addDigitalChannel(daqOUT2p, daqOUT_devid, 'Port0/Line1', 'OutputOnly');
        addDigitalChannel(daqOUTIOI, daqOUT_devid, 'Port0/Line2', 'OutputOnly'); %start/stop
        addAnalogOutputChannel(daqOUTtrig, daqOUT_devid, 'ao1', 'Voltage');
        % Initialize values
        outputSingleScan(daqOUTLED, 0);
        outputSingleScan(daqOUT2p, 0);
        outputSingleScan(daqOUTIOI, 0);
        daqOUTtrig.IsContinuous = true;
        % %%% *** XXX TODO just putting in 1000 to make the trigger easy to construct in preallocate mmf
        daqOUTtrig.Rate = 1000;
        disp([mfilename ': Configured DAQ output.');
    end
    if isempty(analogIN)
        error([mfilename ': Problem configuring NI DAQ IN device.']);
    end
    if isempty(daqOUTLED) || isempty(daqOUT2p) || isempty(daqOUTIOI) || ...
            isempty(daqOUTtrig)
        error([mfilename ': Problem configuring NI DAQ OUT device.']);
    end