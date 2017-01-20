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

% Last Modified by GUIDE v2.5 19-Jan-2017 12:07:25

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

% Data directory, unit, and tag settings
handles.datatxt = 'c:\imager_data\xx0';
handles.unit = 'u000_000';
handles.time_tag = 0;

% Turn off UI buttons that are not accessible
set(handles.startAcquisition, 'Enable', 'off');
set(handles.captureImage, 'Enable', 'off');

% Set up audio output for tracking master-slave communication
handles.blip = audioplayer(10 * sin(linspace(0, 2 * pi, 32)), 30000);

% Create video object
%   Putting the object into manual trigger mode and then
%   starting the object will make GETSNAPSHOT return faster
%   since the connection to the camera will already have
%   been established.
handles.video = videoinput('pointgrey', 1, 'F7_Raw16_1920x1200_Mode0');
set(handles.video, 'TimerPeriod', 0.05, 'TimerFcn', @timerhandler);
triggerconfig(handles.video, 'manual');
handles.video.FramesPerTrigger = Inf; % Capture frames until we manually stop it
handles.video.TriggerRepeat = Inf;
%handles.video.FrameGrabInterval = 2; % Dependent on the mode selected & memory
%available.  Will try without setting this, but if need be, we can select
%only every nth frame. mmf
% Define video source
handles.src = getselectedsource(handles.video);
handles.src.Tag = 'ISI';
FPS = handles.src.FrameRate;
IMGSIZE = handles.video.VideoResolution;
camImBands = handles.video.NumberOfBands;

% Remove tickmarks and labels that are inserted when using IMAGE
set(handles.cameraAxes, 'YTick', [], 'XTick', []);
set(handles.histAxes, 'YTick', []);
set(handles.jetAxes, 'YTick', [], 'XTick', []);
set(handles.jetMapAxes, 'YTick', []);

% Create image in the same position as GUI camera axes
camImPos = get(handles.cameraAxes, 'Position');
camImWpx = camImPos(3);
camImHpx = camImPos(4);
% NOTE: This image handling currently assumes monochrome source, not color.
handles.cameraImage = imshow(uint16(zeros(camImHpx, camImWpx, camImBands)), ...
    'Parent', handles.cameraAxes);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes slimImager wait for user response (see UIRESUME)
uiwait(handles.slimImager);


function timerhandler(varargin)
if ~isempty(gco)
    %% Update handles
    %handles = guidata(gcf);
    %% Get picture using GETSNAPSHOT and put it into axes using IMAGE
    %I = getsnapshot(handles.video);
    %handles.cameraImage = imshow(I, 'Parent', handles.cameraAxes);
    guiUpdate;
else
    % Clean up - delete any image acquisition objects
    delete(imaqfind);
end


% --- Outputs from this function are returned to the command line.
function varargout = slimImager_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Return an empty string, GUI needs no output.
varargout{1} = ''; %handles.output;


% --- Executes when user attempts to close slimImager.
function slimImager_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to slimImager (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make sure video is stopped
%%% XXX *** doesn't always work... make function to check status and close?
%stop(handles.video);
% Close GUI
delete(hObject);
delete(imaqfind);


% --- Executes on button press in cameraToggle.
function cameraToggle_Callback(hObject, eventdata, handles)
% hObject    handle to cameraToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Start or stop camera
if strcmp(get(handles.cameraToggle, 'String'), 'Start Camera')
      % Camera is off. Change button string and start camera.
      set(handles.cameraToggle, 'String', 'Stop Camera');
      start(handles.video);
      set(handles.startAcquisition, 'Enable', 'on');
      set(handles.captureImage, 'Enable', 'on');
else
      % Camera is on. Stop camera and change button string.
      set(handles.cameraToggle, 'String', 'Start Camera');
      stop(handles.video);
      set(handles.startAcquisition, 'Enable', 'off');
      set(handles.captureImage, 'Enable', 'off');
end


% --- Executes on button press in captureImage.
function captureImage_Callback(hObject, eventdata, handles)
% hObject    handle to captureImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guiUpdate;


function guiUpdate(varargin)
% Update handles
handles = guidata(gcf);

% Plot image snapshot in large panel
axes(handles.cameraAxes);
%set(handles.cameraAxes, 'YTick', [], 'XTick', []);
I = getsnapshot(handles.video);
handles.cameraImage = imshow(I, 'Parent', handles.cameraAxes);
axis off;

% Plot histogram of image in middle panel
axes(handles.histAxes);
%set(handles.histAxes, 'YTick', []);
%%% XXX *** might want to set up 'BinEdges',edges,'BinCounts',counts
handles.histPlot = histogram(handles.histAxes, I);
BinLims = handles.histPlot.BinLimits;
% set(handles.histAxes, 'YTick', [] , 'XTick', BinLims, ...
%     'XTickLabel', {num2str(BinLims(1)), num2str(BinLims(2))}, ...
%     'XLim', [0 (2^16 - 1)], 'TickDir', 'out');
set(handles.histAxes, 'TickDir', 'out', 'XGrid', 'on', ...
    'YTick', [], 'YTickLabel', {}, ...
    'XTick', [0 (2^16 - 1)], 'XTickLabel', {0, (2^16 - 1)}, ...
    'XLim', [0 (2^16 - 1)]);
hA = get(handles.histAxes); %%% DEBUG
axis off;

% Plot jet verson of snapshot to show image saturation
jetmap = jet;
jetmap((end-2):end, :) = 1;
axes(handles.jetAxes);
colormap(jetmap);
%handles.jetImage = image(handles.jetAxes, I);
handles.jetImage = imshow(I, 'Colormap', jetmap, ...
    'DisplayRange', [0 (2^16 - 1)], 'Parent', handles.jetAxes);
axis off

% Color the colormap bar under jet
axes(handles.jetMapAxes);
%set(handles.jetMapAxes, 'XTick', []);
colormap(jetmap);
handles.jetMap = image(handles.jetMapAxes, 1:64);
axis off;


% save('testframe.mat', 'frame');
% disp('Frame saved to file ''testframe.mat''');
% % r = questdlg('Do you want to save it?','Single Grab','Yes','No','Yes');
% % if(strcmp(r,'Yes'))
% %     inputdlg('Please enter description:','Image Grab',1,{'No description'},'on');
% %     animal = get(findobj('Tag','animalEnter'),'String');
% %     unit   = get(findobj('Tag','unitEnter'),'String');
% %     expt   = get(findobj('Tag','exptEnter'),'String');
% %     datadir= get(findobj('Tag','dataEnter'),'String');
% %     tag    = get(findobj('Tag','tagEnter'),'String');
% % 
% %     dd = strcat(datadir, filsep, animal, filesep, 'grabs', filesep);
% %     if(~exist(dd, 'dir'))
% %         mkdir(dd);
% %     end
% %     fname = strcat(dd, 'grab_', animal, ...
% %         '_', unit, '_', ...
% %         expt, '_', datestr(now));
% %     fname = strrep(fname, ' ', '_');
% %     fname = strrep(fname, ':', '');
% %     fname = strrep(fname, '-', '');
% %     fname = strcat(fname, '.mat');
% %     fname(2) = ':';
% %     %%% XXX *** update for videoinput
% %     save(fname,'frame');
% % end


% --- Executes during object creation, after setting all properties.
function cameraAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cameraAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in startAcquisition.
function startAcquisition_Callback(hObject, eventdata, handles)
% hObject    handle to startAcquisition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Start/Stop acquisition
if strcmp(get(handles.startAcquisition,'String'),'Start Acquisition')
      % Camera is not acquiring. Change button string and start acquisition.
      set(handles.startAcquisition,'String','Stop Acquisition');
      trigger(handles.video);
else
      % Camera is acquiring. Stop acquisition, save video data,
      % and change button string.
      stop(handles.video);
      disp('Saving captured video...');
      videodata = getdata(handles.video);
      save('testvideo.mat', 'videodata');
      disp('Video saved to file ''testvideo.mat''');
      start(handles.video); % Restart the camera
      set(handles.startAcquisition,'String','Start Acquisition');
end


% --- Executes on button press in illuminationEnable.
function illuminationEnable_Callback(hObject, eventdata, handles)
% hObject    handle to illuminationEnable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of illuminationEnable


% --- Executes on button press in illuminationROI.
function illuminationROI_Callback(hObject, eventdata, handles)
% hObject    handle to illuminationROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function pathName_Callback(hObject, eventdata, handles)
% hObject    handle to pathName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pathName as text
%        str2double(get(hObject,'String')) returns contents of pathName as a double


% --- Executes during object creation, after setting all properties.
function pathName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pathName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in directory.
function directory_Callback(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%global imagerhandles;
dir = uigetdir('', 'Select data directory');
if dir ~= 0
    %imagerhandles.datadir = dir;
    handles.datadir = dir;
    set(findobj('Tag', 'datatxt'), 'String', dir);
end


function unitEnter_Callback(hObject, eventdata, handles)
% hObject    handle to unitEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of unitEnter as text
%        str2double(get(hObject,'String')) returns contents of unitEnter as a double


% --- Executes during object creation, after setting all properties.
function unitEnter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to unitEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function tagEnter_Callback(hObject, eventdata, handles)
% hObject    handle to tagEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagEnter as text
%        str2double(get(hObject,'String')) returns contents of tagEnter as a double


% --- Executes during object creation, after setting all properties.
function tagEnter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function exptEnter_Callback(hObject, eventdata, handles)
% hObject    handle to exptEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of exptEnter as text
%        str2double(get(hObject,'String')) returns contents of exptEnter as a double


% --- Executes during object creation, after setting all properties.
function exptEnter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exptEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function animalEnter_Callback(hObject, eventdata, handles)
% hObject    handle to animalEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of animalEnter as text
%        str2double(get(hObject,'String')) returns contents of animalEnter as a double


% --- Executes during object creation, after setting all properties.
function animalEnter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animalEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function timeEnter_Callback(hObject, eventdata, handles)
% hObject    handle to timeEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timeEnter as text
%        str2double(get(hObject,'String')) returns contents of timeEnter as a double


% --- Executes during object creation, after setting all properties.
function timeEnter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeEnter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in streamMemory.
function streamMemory_Callback(hObject, eventdata, handles)
% hObject    handle to streamMemory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of streamMemory
