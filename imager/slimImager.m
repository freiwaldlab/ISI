function varargout = slimImager(varargin)
% SLIMIMAGER MATLAB code for slimImager.fig
%      SLIMIMAGER, by itself, creates a new SLIMIMAGER or raises the existing
%      singleton*.
%
%      H = SLIMIMAGER returns the handle to a new SLIMIMAGER or the handle to
%      the existing singleton*.
%
%      SLIMIMAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLIMIMAGER.M with the given input arguments.
%
%      SLIMIMAGER('Property','Value',...) creates a new SLIMIMAGER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before slimImager_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to slimImager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help slimImager

% Last Modified by GUIDE v2.5 28-Aug-2017 12:07:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @slimImager_OpeningFcn, ...
                   'gui_OutputFcn',  @slimImager_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before slimImager is made visible.
function slimImager_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to slimImager (see VARARGIN)
global imagerhandles imagerWinOffYpx prefixDate

% Data directory, unit, and tag settings
handles.datatxt = 'D:\';
handles.time_tag = 0;
set(findobj('Tag', 'datatxt'), 'string', handles.datatxt);
animal = get(findobj('Tag', 'animaltxt'), 'string')
datadir = get(findobj('Tag', 'datatxt'), 'string')
tag = get(findobj('Tag', 'tagtxt'), 'string')
pathBase = [datadir filesep prefixDate '_' deblank(animal)]

% Get screen information for window positioning
scpx = get(0, 'ScreenSize');
% Set window position
siw = gcf;
sipx = getpixelposition(siw);
setpixelposition(siw, [scpx(1) ...
    (scpx(4) - sipx(4) - imagerWinOffYpx) ...
    sipx(3) sipx(4)]);

% Turn off UI buttons that are not accessible
%set(handles.startAcquisition, 'Enable', 'off');
set(handles.captureImage, 'Enable', 'off');

% Remove tickmarks and labels that are inserted when using IMAGE
set(handles.cameraAxes, 'YTick', [], 'XTick', [], 'Visible', 'off');
set(handles.histAxes, 'YTick', [], 'XTick', [], 'XLim', [0 (2^16 - 1)]);
box(handles.histAxes, 'on')
set(handles.jetAxes, 'YTick', [], 'XTick', []);
box(handles.jetAxes, 'on')
set(handles.jetMapAxes, 'YTick', [], 'XTick', []);
box(handles.jetMapAxes, 'on')

% Create image in the same position as GUI camera axes
handles.video = videoinput('pointgrey', 1, 'F7_Raw16_1920x1200_Mode0');
% closeopenvid
%handles = configVideoInput(handles, 'manual');
% hardwarevid
handles = configVideoInput(handles, 'hardware');
start(handles.video);

camImPos = get(handles.cameraAxes, 'Position');
camImWpx = camImPos(3);
camImHpx = camImPos(4);
camImBands = handles.video.NumberOfBands;
handles.cameraImage = imshow(uint16(zeros(camImHpx, camImWpx, camImBands)), ...
    'Parent', handles.cameraAxes);

% Color the colormap bar under jet
jetmap = jet;
jetmap((end-2):end, :) = 1;
handles.jetcolmap = jetmap;
colormap(handles.jetcolmap);
handles.jetMap = image(handles.jetMapAxes, 1:64);
set(handles.jetMapAxes, 'YTick', [], 'XTick', []);
box(handles.jetMapAxes, 'on');

imagerhandles = handles;

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes slimImager wait for user response (see UIRESUME)
uiwait(handles.slimImager);


function timerhandler(varargin)
    if ~isempty(gco)
        guiUpdate
    end


% --- Outputs from this function are returned to the command line.
function varargout = slimImager_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Return an empty string, GUI needs no output
varargout{1} = ''; %handles.output;


% --- Executes when user attempts to close slimImager.
function slimImager_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to slimImager (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global daqOUTtrig daqOUTlist
    if isfield(handles, 'video')
        if isvalid(handles.video)
            delete(handles.video);
            clear handles.video
            delete(imaqfind);
        end
    end
    if isvalid(daqOUTtrig)
        stop(daqOUTtrig);
        if event.hasListener(daqOUTtrig, 'DataRequired')
            delete(daqOUTlist);
            clear global daqOUTlist
        end
        outputSingleScan(daqOUTtrig, 0);
    end
    % Close GUI
    delete(hObject);


% --- Executes on button press in cameraToggle.
function cameraToggle_Callback(hObject, eventdata, handles)
% hObject    handle to cameraToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles daqOUTtrig daqOUTlist FPS 
handles = imagerhandles;
% Start or stop camera
if strcmp(get(handles.cameraToggle, 'string'), 'Start Camera')
    % Camera is off. Change button string and start camera.
    set(handles.cameraToggle, 'string', 'Stop Camera');
    %set(handles.startAcquisition, 'Enable', 'on');
    set(handles.captureImage, 'Enable', 'on');
    if isfield(handles, 'video')
        if isvalid(handles.video)
            flushdata(handles.video);
            set(handles.video, 'TimerPeriod', 0.05, ...
                'TimerFcn', @timerhandler);
            if isvalid(daqOUTtrig)
                stop(daqOUTtrig);
                if event.hasListener(daqOUTtrig, 'DataRequired')
                    delete(daqOUTlist);
                    clear global daqOUTlist
                end
                outputSingleScan(daqOUTtrig, 0);
            end
            msec_per_frame = ceil(1000 / FPS);
            highV = 5;
            dutyCycle = 0.1;
            trigSingle = zeros(msec_per_frame, 1);
            trigSingle(end-round(dutyCycle*length(trigSingle))-1:end-1) = highV;
            trigSize = size(trigSingle, 1);
            % This preview-like triggering should be continuous until 
            % until stopped, but meet minimum queueable scan number of 500.
            outRate = 500; %daqOUTtrig.Rate;
            % Now we have one cycle, use repmat to make copies
            trigSeq = repmat(trigSingle, [floor(outRate / trigSize), 1]);
            cushion = zeros(mod(outRate, size(trigSeq, 1)), 1);
            %trigSeq = trigSingle;
            %cushion = zeros(mod(outRate, trigSize), 1);
            trigSeq = [trigSeq; cushion];
            
            queueOutputData(daqOUTtrig, trigSeq);
            daqOUTlist = addlistener(daqOUTtrig, 'DataRequired', ...
                @(src,event) src.queueOutputData(trigSeq));
            startBackground(daqOUTtrig);
        else
            msgbox('Could not find valid video input.')
        end
    else
        msgbox('Could not find video input.')
    end
else
    % Camera is on. Stop camera and change button string.
    set(handles.cameraToggle, 'string', 'Start Camera');
    %set(handles.startAcquisition, 'Enable', 'off');
    set(handles.captureImage, 'Enable', 'off');
    % Delete any preview image acquisition objects
    if isvalid(daqOUTtrig)
        stop(daqOUTtrig);
        if event.hasListener(daqOUTtrig, 'DataRequired')
            delete(daqOUTlist);
            clear global daqOUTlist
        end
        outputSingleScan(daqOUTtrig, 0);
    end
    if isfield(handles, 'video')
        if isvalid(handles.video)
            set(handles.video, 'TimerPeriod', 0.05, 'TimerFcn', []);
            flushdata(handles.video);
        else
            msgbox('Could not find valid video input.')
        end
    else
        msgbox('Could not find video input.')
    end
end

imagerhandles = handles;


% --- Executes on button press in captureImage.
function captureImage_Callback(hObject, eventdata, handles)
    global imagerhandles pathBase prefixDate
    handles = imagerhandles;
    
    if ~exist(pathBase, 'dir')
        mkdir(pathBase);
        warning([mfilename ': Base path did not exist. Created [' ...
            pathBase '].']);
    end
    
    if isfield(handles, 'video')
        if isvalid(handles.video)
            if handles.video.FramesAvailable > 0
                Is = rot90(getdata(handles.video, ...
                    handles.video.FramesAvailable), 2);
                I = Is(:,:,end);
                handles.cameraImage = imshow(I, 'Parent', ...
                    handles.cameraAxes);
            end
        end
    end
    if exist('I', 'var')
        % Plot image histogram in middle panel
        handles.histPlot = histogram(handles.histAxes, I);
        set(handles.histAxes, 'YTick', [], 'XTick', [], ...
            'XLim', [0 (2^16 - 1)]);
        box(handles.histAxes, 'on');
        
        % Plot jet verson of snapshot to show image saturation
        handles.jetImage = imshow(I, 'Colormap', handles.jetcolmap, ...
            'DisplayRange', [0 (2^16 - 1)], 'Parent', handles.jetAxes);
        box(handles.jetAxes, 'on');
        
        pfix = [datestr(now, 'yymmdd') 'd' datestr(now, 'HHMMSS') 't'];
        capfname = strcat(pathBase, filesep, pfix, '_capture.png');
        clear pfix
        imwrite(I, capfname);
        disp([mfilename ': Saved image [' capfname '].']);
    else
        error([mfilename ': Could not capture image.']);
    end
    
    imagerhandles = handles;


function guiUpdate(varargin)
    global imagerhandles
    handles = imagerhandles;
    camImPos = get(handles.cameraAxes, 'Position');
    camImWpx = camImPos(3);
    camImHpx = camImPos(4);
    if isfield(handles, 'video')
        if isvalid(handles.video)
            if handles.video.FramesAvailable > 0
                %Is = fliplr(getdata(handles.video, handles.video.FramesAvailable));
                %Is = flipud(getdata(handles.video, handles.video.FramesAvailable));
                Is = rot90(getdata(handles.video, handles.video.FramesAvailable), 2);
                %Is = getdata(handles.video, handles.video.FramesAvailable);
                I = Is(:,:,end);
                handles.cameraImage = imshow(I, 'Parent', handles.cameraAxes);
            end
        else
            I = uint16(zeros(camImHpx, camImWpx, 1));
        end
    else
        I = uint16(zeros(camImHpx, camImWpx, 1));
    end
    if ~exist('I', 'var')
        % If no new preview image exists, no need to update the GUI
        imagerhandles = handles;
        return
    end

    % Plot image histogram in middle panel
    handles.histPlot = histogram(handles.histAxes, I);
    set(handles.histAxes, 'YTick', [], 'XTick', [], 'XLim', [0 (2^16 - 1)]);
    box(handles.histAxes, 'on');

    % Plot jet verson of snapshot to show image saturation
    handles.jetImage = imshow(I, 'Colormap', handles.jetcolmap, ...
        'DisplayRange', [0 (2^16 - 1)], 'Parent', handles.jetAxes);
    box(handles.jetAxes, 'on');
    
    imagerhandles = handles;


% --- Executes during object creation, after setting all properties.
function cameraAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cameraAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in startAcquisition.
% function startAcquisition_Callback(hObject, eventdata, handles)
% % hObject    handle to startAcquisition (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% % Start/Stop acquisition
% if strcmp(get(handles.startAcquisition, 'String'), 'Start Acquisition')
%       % Camera is not acquiring. Change button string and start acquisition.
%       set(handles.startAcquisition, 'string', 'Stop Acquisition');
%       trigger(handles.video);
% else
%       % Camera is acquiring. Stop acquisition, save video data,
%       % and change button string.
%       if isfield(handles, 'video')
%           if isvalid(handles.video)
%               disp([mfilename 'FIX ME FIX ME FIX ME Saving captured video...']);
%               %videodata = fliplr(getdata(handles.video));
%               %videodata = flipud(getdata(handles.video));
%               videodata = rot90(getdata(handles.video), 2);
%               %videodata = getdata(handles.video);
%               save('testvideo.mat', 'videodata');
%               disp('Video saved to file ''testvideo.mat''');
%           end
%       end
%       set(handles.startAcquisition, 'string', 'Start Acquisition');
% end


% % --- Executes on button press in illuminationEnable.
% function illuminationEnable_Callback(hObject, eventdata, handles)
% % hObject    handle to illuminationEnable (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


% % --- Executes on button press in illuminationROI.
% function illuminationROI_Callback(hObject, eventdata, handles)
% % hObject    handle to illuminationROI (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


function datatxt_Callback(hObject, eventdata, handles)
% hObject    handle to datatxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles pathBase prefixDate
dir = get(findobj('Tag', 'datatxt'), 'string');
set(findobj('Tag', 'datatxt'), 'string', dir);
animal = get(findobj('Tag', 'animaltxt'), 'string');
%unit = get(findobj('Tag', 'unittxt'), 'string');
%expt = get(findobj('Tag', 'expttxt'), 'string');
datadir = get(findobj('Tag', 'datatxt'), 'string');
tag = get(findobj('Tag', 'tagtxt'), 'string');
%trial = str2double(cmd(3:end));
pathBase = [datadir filesep prefixDate '_' deblank(animal)];
imagerhandles = handles;


% --- Executes during object creation, after setting all properties.
function datatxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datatxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in directory.
function directory_Callback(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global imagerhandles pathBase prefixDate
    dir = uigetdir(get(findobj('Tag', 'datatxt'), 'string'), ...
        'Select Data Path');
    if dir ~= 0
        set(findobj('Tag', 'datatxt'), 'string', dir);
        animal = get(findobj('Tag', 'animaltxt'), 'string');
        %unit = get(findobj('Tag', 'unittxt'), 'string');
        %expt = get(findobj('Tag', 'expttxt'), 'string');
        datadir = get(findobj('Tag', 'datatxt'), 'string');
        tag = get(findobj('Tag', 'tagtxt'), 'string');
        %trial = str2double(cmd(3:end));
        pathBase = [datadir filesep prefixDate '_' deblank(animal)];
    end
    imagerhandles = handles;


function animaltxt_Callback(hObject, eventdata, handles)
% hObject    handle to animaltxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of animaltxt as text
%        str2double(get(hObject,'String')) returns contents of animaltxt as a double


% --- Executes during object creation, after setting all properties.
function animaltxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animaltxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function timetxt_Callback(hObject, eventdata, handles)
% hObject    handle to timetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function timetxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in streamMemory.
function streamMemory_Callback(hObject, eventdata, handles)
% hObject    handle to streamMemory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% function unittxt_Callback(hObject, eventdata, handles)
% % hObject    handle to unittxt (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


% % --- Executes during object creation, after setting all properties.
% function unittxt_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to unittxt (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


% function tagtxt_Callback(hObject, eventdata, handles)
% % hObject    handle to tagtxt (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


% % --- Executes during object creation, after setting all properties.
% function tagtxt_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to tagtxt (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end


% function expttxt_Callback(hObject, eventdata, handles)
% % hObject    handle to expttxt (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)


% % --- Executes during object creation, after setting all properties.
% function expttxt_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to expttxt (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
