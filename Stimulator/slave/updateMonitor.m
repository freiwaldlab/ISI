function updateMonitor
    global Mstate screenPTR
    
    cal_path = 'C:\Dropbox\ISI\Stimulator\master\Calibration\170201';
    
    updateMonitorValues
    
    switch Mstate.monitor
        case 'LCD'
            cal_file = strcat(cal_path, filesep, 'LCD (big) 1-8-11/LUT.mat');
        case 'CRT'
            cal_file = strcat(cal_path, filesep, 'CRT 7-9-11 UDT/LUT.mat');
        case 'TEL'
            cal_file = strcat(cal_path, filesep, 'TELEV 9-29-10/LUT.mat');
        case '40in'
            cal_file = strcat(cal_path, filesep, 'NEWTV 3-15-12/LUT.mat');
        case 'VPX'
            % Generate a linear table until calibration is done %%% TODO
            % *** testing 170203 LUT file
            %bufLUT = (0:255) / 255;
            %bufLUT = bufLUT' * [1 1 1];
            %cal_file = [];
            cal_file = strcat(cal_path, filesep, '170203t1509_LUT.mat');
        case 'LIN'
            % Generate a linear table
            bufLUT = (0:255) / 255;
            bufLUT = bufLUT' * [1 1 1];
            cal_file = [];
        otherwise
            disp('updateMonitor ERROR: Unknown monitor type specified.')
    end
    if exist(cal_file, 'file')
        load(cal_file, 'bufLUT')
        disp('updateMonitor: Loaded gamma correction LUT.')
    elseif ~isempty(cal_file)
        disp('updateMonitor ERROR: Unable to load gamma correction LUT.')
    end
        
    % Set gamma LUT
    Screen('LoadNormalizedGammaTable', screenPTR, bufLUT);