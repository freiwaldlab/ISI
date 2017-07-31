%% Settings
global DcomState Mstate
CalPath = 'C:\Dropbox\ISI\Stimulator\calibration\data';
OutFile = [CalPath filesep '170210t1620_calvals'];
OutFileCLUT = [CalPath filesep '170210t1620_clutvals'];
MonitorCode = 'VPX';

% Toggle between initial measurements and checking after applying 
% a calibration
CalibrationApplied = true;

% Set how long to pause for meter
RespPause = 2;

%% Close any previously opened ports
port = instrfindall;
if ~isempty(port)
    fclose(port); 
    delete(port);
    clear port;
end

%% Initiate communication with meter and slave
CS100A = serial('COM3', 'BaudRate', 4800, 'DataBits', 7, ...
    'Parity', 'even', 'StopBits', 2,'FlowControl', 'hardware', ...
    'InputBufferSize', 4096);
fopen(CS100A);
CS100A.Timeout = 6.0;
CS100A.Terminator = 'CR/LF';

% Configure monitor and make sure linear LUT is selected
configureMstate
if CalibrationApplied
    Mstate.monitor = MonitorCode;
else
    Mstate.monitor = 'LIN';
end
updateMonitorValues
configDisplayCom

%% Confirm communication with meter
fprintf(CS100A, 'CS100A');
msg = fscanf(CS100A);
msg = regexprep(msg, '\r\n', '');
if ~isempty(msg) && strcmp(msg, 'ER00')
    disp([mfilename ': Received expected message from meter, ' ...
        'communication established.'])
elseif ~strcmp(msg, 'ER00')
    error([mfilename ': Received unexpected message from meter (' ...
        msg '), not sure whether communication was established.'])
else
    error([mfilename ': Received no message from meter, ' ...
        'communication failed.'])
end
flushinput(CS100A);

%% Set measurement mode
%mode = '00'; % Minolta calibration standard
mode = '04'; % absolute
fprintf(CS100A, strcat('MDS,', mode));
pause(RespPause)
msg = fscanf(CS100A);
msg = regexprep(msg, '\r\n', '');
if strcmp(msg, 'OK00')
    disp([mfilename ': Measurement mode set.']);
elseif iserror(msg)
    error([mfilename ': Unable to set measurement mode.']);
    return
end
clear msg
flushinput(CS100A);

%% Make one test measurement
fprintf(CS100A, 'MES');
pause(RespPause)
msg = fscanf(CS100A);
msg = regexprep(msg, '\r\n', '');
if ~iserror(msg)
    disp([mfilename ': Test measurement recorded (' msg ').']);
else
    error([mfilename ': Unable to record a test measurement.']);
    return
end
clear msg
flushinput(CS100A);

%% Perform per-channel luminance measurements

% Clear the serial buffer
flushinput(CS100A);

% Settings and allocations
chans = 'RGB';
reps = 3;
dom = 0:1:255;
Y = NaN(length(chans), length(dom));
x = NaN(length(chans), length(dom));
y = NaN(length(chans), length(dom));
stat = cell(length(chans), length(dom));
colorcode = cell(length(chans), length(dom));
% Record and reformat measurements
tmeas = tic;
for c = 1:length(chans)
    for i = 1:length(dom)
        % Format luminance string to send to slave
        dispRGB = '000000000';
        dispRGB(3*(c-1)+1:c*3) = sprintf('%03d', dom(i));
        % Send display command to slave and wait for response
        fwrite(DcomState.serialPortHandle, ['Q;RGB;' dispRGB ';~']);
        waitforDisplayResp
        disp([mfilename ': Measuring average ' chans(c) ' luminance ' ...
            'at intensity ' sprintf('%03d', dom(i)) ' (' dispRGB ') ' ...
            'over ' num2str(reps) ' measurement(s).'])
        lumY = NaN(reps, 1);
        chmx = NaN(reps, 1);
        chmy = NaN(reps, 1);
        for a = 1:reps
            % Clear serial buffer directly before command
            flushinput(CS100A);
            % Send measurement command and wait
            fprintf(CS100A, 'MES');
            pause(RespPause)
            % Fetch measurements
            [lumY(a),chmx(a),chmy(a),status] = fetchmeas(CS100A);
        end
        % Store CIE values
        Y(c,i) = mean(lumY(:));
        Ydev = std(lumY(:));
        x(c,i) = mean(chmx(:));
        xdev = std(chmx(:));
        y(c,i) = mean(chmy(:));
        ydev = std(chmy(:));
        stat{c,i} = status;
        colorcode{c,i} = dispRGB;
        disp([mfilename ': ' stat{c,i} '; Y = ' sprintf('%06.4f', Y(c,i)) ...
            ' sd ' sprintf('%06.4f', Ydev) ...
            '; x = ' sprintf('%06.4f', x(c,i)) ...
            ' sd ' sprintf('%06.4f', xdev) ...
            '; y = ' sprintf('%06.4f', y(c,i)) ...
            ' sd ' sprintf('%06.4f', ydev)])
    end
end
measure_time = toc(tmeas);
disp([mfilename ': Per-channel measurements took a combined total of ' ...
    num2str(measure_time) ' sec.'])
save(OutFile, 'Y', 'x', 'y', 'stat', 'dom', 'colorcode')
fwrite(DcomState.serialPortHandle, 'C;~')
clear Y y x Ydev ydev xdev stat colorcode dom dispRGB

% %% Perform cLUT measurements 
% 
% % Clear the serial buffer
% flushinput(CS100A);
% 
% % Settings and allocations
% chans = 'RGB';
% dom = 0:8:256;
% dom(end) = 255;
% combos = nchoosekwr(dom, length(chans));
% Y = [];
% x = [];
% y = [];
% stat = cell(1);
% colorcode = cell(1);
% % Record and reformat measurements
% tmeas = tic;
% for e = 1:length(combos)
%     % Format luminance string to send to slave
%     dispRGB = sprintf('%03d%03d%03d', combos(e,1), combos(e,2), ...
%         combos(e,3));
%     % Send display command to slave and wait for response
%     fwrite(DcomState.serialPortHandle, ['Q;RGB;' dispRGB ';~']);
%     waitforDisplayResp
%     disp([mfilename ': Measuring average luminance ' ...
%         'at ' dispRGB '.'])
%     % Clear serial buffer directly before command
%     flushinput(CS100A);
%     % Send measurement command and wait
%     fprintf(CS100A, 'MES');
%     pause(RespPause)
%     % Fetch measurements
%     [Y(e),x(e),y(e),status] = fetchmeas(CS100A);
%     % Store CIE values
%     stat{e} = status;
%     colorcode{e} = dispRGB;
%     disp([mfilename ': ' stat{e} '; Y = ' sprintf('%06.4f', Y(e)) ...
%         '; x = ' sprintf('%06.4f', x(e)) ...
%         '; y = ' sprintf('%06.4f', y(e))])
% end
% measure_time = toc(tmeas);
% disp([mfilename ': Measurements took a combined total of ' ...
%     num2str(measure_time) ' sec.'])
% save(OutFileCLUT, 'Y', 'x', 'y', 'stat', 'dom', 'colorcode')
% fwrite(DcomState.serialPortHandle, 'C;~')


%% Close connections and clean up
fclose(CS100A);

%% Define functions
function errbool = iserror(mess)
    mess = regexprep(mess, '\r\n', '');
    if isempty(mess)
        warning([mfilename ': Returned message is empty.']);
    end
    switch mess
        case 'ER00'
            error([mfilename ': Command not understood.']);
            errbool = true;
        case 'ER10'
            error([mfilename ': Luminance or chromaticity out of range.']);
            errbool = true;
        case 'ER11'
            error([mfilename ': Memory value error.']);
            errbool = true;
        case 'ER20'
            error([mfilename ': Cannot access EEPRON.']);
            errbool = true;
        case 'ER30'
            error([mfilename ': Battery too low.']);
            errbool = true;
        otherwise
            errbool = false;
    end
end

function [lumY,chmx,chmy,status] = fetchmeas(com)
    msg = fscanf(com);
    msg = regexprep(msg, '\r\n', '');
    if ~iserror(msg)
        % Reformat response
        data = msg;
        dataspl = strtrim(strsplit(data, ','));
        if ~(length(dataspl) == 4)
            error([mfilename ': Received unexpected ' ...
                'measurement format (' msg ').'])
        end
        % Parse values
        status = dataspl{1};
        lumY = str2double(dataspl{2});
        chmx = str2double(dataspl{3});
        chmy = str2double(dataspl{4});
    end
end

function y = nchoosekwr(v, n)
% Subject: nchoosek with replacement
% From: pjacklam@online.no (...
% Date: 19 Aug, 2003 08:20:06
% https://www.mathworks.com/matlabcentral/newsreader/view_thread/52610
    if n == 1
        y = v;
    else
        v = v(:);
        y = [];
        m = length(v);
        if m == 1
            y = zeros(1, n);
            y(:) = v;
        else
            for i = 1 : m
                y_recr = nchoosekwr(v(i:end), n-1);
                s_repl = zeros(size(y_recr, 1), 1);
                s_repl(:) = v(i);
                y = [ y ; s_repl, y_recr ];
            end
        end
    end
end