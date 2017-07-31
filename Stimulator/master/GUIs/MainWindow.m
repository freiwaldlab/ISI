function varargout = MainWindow(varargin)
% MAINWINDOW M-file for MainWindow.fig
%      MAINWINDOW, by itself, creates a new MAINWINDOW or raises the existing
%      singleton*.
%
%      H = MAINWINDOW returns the handle to a new MAINWINDOW or the handle to
%      the existing singleton*.
%
%      MAINWINDOW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAINWINDOW.M with the given input arguments.
%
%      MAINWINDOW('Property','Value',...) creates a new MAINWINDOW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MainWindow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MainWindow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MainWindow_OpeningFcn, ...
                   'gui_OutputFcn',  @MainWindow_OutputFcn, ...
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


% --- Executes just before MainWindow is made visible.
function MainWindow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MainWindow (see VARARGIN)

% Choose default command line output for MainWindow
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MainWindow wait for user response (see UIRESUME)
% uiwait(handles.figure1);

global GUIhandles Mstate %shutterState
Mstate.running = 0;

% Set GUI fields to the default Mstate values
set(handles.intrinsicTog, 'value', 1);
set(handles.intrinsicflag, 'value', 1)
set(handles.twophotonTog, 'value', 0);
set(handles.twophotonflag, 'value', 0)
set(handles.screendistance, 'string', num2str(Mstate.screenDist))
set(handles.analyzerRoots, 'string', Mstate.analyzerRoot)
set(handles.animal, 'string', Mstate.anim)
set(handles.unitcb, 'string', Mstate.unit)
set(handles.exptcb, 'string', Mstate.expt)
set(handles.hemisphere, 'string', Mstate.hemi)
set(handles.screendistance, 'string', Mstate.screenDist)
set(handles.monitor, 'string', Mstate.monitor)
set(handles.stimulusIDP, 'string', Mstate.stimulusIDP)

GUIhandles.main = handles;

% Currently, no eye shutter is supposed.
% shutterState.use=0;
% shutterState.ini=0;


% --- Outputs from this function are returned to the command line.
function varargout = MainWindow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% % Get default command line output from handles structure
%varargout{1} = handles.output;
% Annoying workaround for window positioning
varargout{1} = gcf;


function animal_Callback(hObject, eventdata, handles)
% hObject    handle to animal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Mstate

Mstate.anim = get(handles.animal, 'string');
anaroot = get(handles.analyzerRoots, 'string');
Mstate.analyzerRoot = anaroot;
roots = parseString(Mstate.analyzerRoot, ';');
%Use the first root path for the logic below
dirinfo = dir([roots{1} filesep Mstate.anim]);

%If the animal folder exists and there are files in it
if length(dirinfo) > 2 
    lastunit = dirinfo(end).name(6:8);
    lastexpt = dirinfo(end).name(10:12);
    newunit = lastunit; 
    %Go to next experiment number
    newexpt = sprintf('%03d', str2double(lastexpt) + 1);
else
    %If animal folder does not exist or there aren't any files.
    %The new folder will be created when you hit the 'run' button
    newunit = '000';
    newexpt = '000';
end

Mstate.unit = newunit;
Mstate.expt = newexpt;
set(handles.exptcb, 'string', newexpt)
set(handles.unitcb, 'string', newunit)

%Send expt info to acquisition
UpdateACQExptName


% --- Executes during object creation, after setting all properties.
function animal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function hemisphere_Callback(hObject, eventdata, handles)
% hObject    handle to hemisphere (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Mstate

%This is not actually necessary since updateMstate is always called prior
%to showing stimuli...
Mstate.hemi = get(handles.hemisphere,'string');


% --- Executes during object creation, after setting all properties.
function hemisphere_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hemisphere (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function screendistance_Callback(hObject, eventdata, handles)
% hObject    handle to screendistance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Mstate

%This is not actually necessary since updateMstate is always called prior
%to showing stimuli...  
Mstate.screenDist = str2double(get(handles.screendistance,'string'));


% --- Executes during object creation, after setting all properties.
function screendistance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to screendistance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in runbutton.
function runbutton_Callback(hObject, eventdata, handles)
% hObject    handle to runbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Mstate imagerhandles GUIhandles trialno analogIN DataPath
global daqOUTtrig daqOUTlist DcomState
mod = getmoduleID;

% Run experiment
if ~Mstate.running
    % If module is of 'mapper' type, send and play but don't run
    if strcmpi(getmoduleID, 'MP')
        Mstate.running = 0;
        updateMstate
        sendPinfo
        waitforDisplayResp
        sendMinfo
        waitforDisplayResp
        msg = ['B;' mod ';-1;~'];
        fwrite(DcomState.serialPortHandle, msg);
        waitforDisplayResp
        startStimulus
        return
    end

    % Check if an analyzer file already exists
    roots = parseString(Mstate.analyzerRoot, ';');    
    for i = 1:length(roots)
        title = [Mstate.anim '_' sprintf('u%s', Mstate.unit) '_' ...
            Mstate.expt];
        dd = [roots{i} filesep Mstate.anim filesep title '.analyzer'];
        if exist(dd, 'file') == 2
            warndlg('Analyzer file already exists. Please advance experiment before running.')
            return
        end
    end
    
    % Check if this data directory already exists
    if get(GUIhandles.main.intrinsicflag, 'value')
        [Oflag, dd] = checkforOverwrite;
        if ~Oflag
            mkdir(dd)
        else
            return
        end
    end
    
    Mstate.running = 1;
    
    updateLstate
    updateMstate    
    
    % Creates 'looperInfo'.
    % Must be done before saving the analyzer file.
    makeLoop
    %Save .analyzer. Do this before running... in case something crashes
    saveExptParams

    set(handles.runbutton, 'string', 'Abort')
  
    % Send initial parameters to display
    sendPinfo
    waitforDisplayResp
    sendMinfo
    waitforDisplayResp
    
    %%%Get the 2photon acquisition ready:
    %Flag for the link with scanimage
    if get(GUIhandles.main.twophotonflag, 'value')
        prepACQ
    end
    
    if get(GUIhandles.main.intrinsicflag, 'value')
        % sendtoImager 'I' runs preallocateTensor, which depends on
        % stimulus time, so moved into run2.m
        %P = getParamStruct;
        %total_time = P.predelay + P.postdelay + P.stim_time;
        %sendtoImager(sprintf(['I %2.3f' 13], total_time))
        
        %Make sure analog in is not running
        analogIN.stop; 
        
        if isvalid(daqOUTtrig)
            disp([mfilename ': daqOUTtrig exists, stopping before running.']);
            stop(daqOUTtrig);
            if event.hasListener(daqOUTtrig, 'DataRequired')
                disp([mfilename ': daqOUTlist exists, deleting before running.']);
                delete(daqOUTlist);
                clear global daqOUTlist
            end
            outputSingleScan(daqOUTtrig, 0);
        end
        
        if strcmp(get(imagerhandles.cameraToggle, 'string'), 'Stop Camera')
            % Camera is on for previewing, so turn off preview.
            set(imagerhandles.cameraToggle, 'string', 'Start Camera');
            set(imagerhandles.startAcquisition, 'Enable', 'off');
            set(imagerhandles.captureImage, 'Enable', 'off');
            % Stop imager GUI updates
            if isfield(imagerhandles, 'video')
                if isvalid(imagerhandles.video)
                    set(imagerhandles.video, 'TimerPeriod', 0.05, ...
                        'TimerFcn', []);
                end
            end
            pause(0.5)
        end
    end
   
    trialno = 1;
    
    %In 2 computer version 'run2' is no longer a loop, but gets recalled
    %after each trial... 
    %In 'endAcquisition' (2ph), below (intrinsic), or 'Displaycb' (no acquisition)
    run2 
    
    %We don't want anything significant to happen after 'run2', so that
    %scanimage will be ready to accept TTL
    
    % Remove video object and clean up after all trials
    if get(GUIhandles.main.intrinsicflag, 'value')
        sendtoImager('C')
    end
else
    %Global flag for interrupt in real-time loop ('Abort')   
    Mstate.running = 0; 
    set(handles.runbutton, 'string', 'Run')    
end

%This is done to ensure that user builds a new stimulus before doing
%'playsample'.  Otherwise it will open the shutter.
%set(GUIhandles.param.playSample,'enable','off')


% --- Executes on button press in unitcb.
function unitcb_Callback(hObject, eventdata, handles)
% hObject    handle to unitcb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Mstate
newunit = sprintf('%03d', str2double(Mstate.unit) + 1);
Mstate.unit = newunit;
set(handles.unitcb, 'string', newunit)
newexpt = '000';
Mstate.expt = newexpt;
set(handles.exptcb, 'string', newexpt)
UpdateACQExptName   %Send expt info to acquisition


% --- Executes on button press in exptcb.
function exptcb_Callback(hObject, eventdata, handles)
% hObject    handle to exptcb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Mstate
newexpt = sprintf('%03d', str2double(Mstate.expt) + 1);
Mstate.expt = newexpt;
set(handles.exptcb, 'string', newexpt)
% Send expt info to acquisition
UpdateACQExptName


% --- Executes on button press in closeDisplay.
function closeDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to closeDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global DcomState
fwrite(DcomState.serialPortHandle, 'C;~')


function analyzerRoots_Callback(hObject, eventdata, handles)
% hObject    handle to analyzerRoots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%This is not actually necessary since updateMstate is always called prior
%to showing stimuli...
Mstate.analyzerRoot = get(handles.analyzerRoots, 'string');


% --- Executes during object creation, after setting all properties.
function analyzerRoots_CreateFcn(hObject, eventdata, handles)
% hObject    handle to analyzerRoots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in REflag.
function REflag_Callback(hObject, eventdata, handles)
% hObject    handle to REflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%mmf
% REbit = get(handles.REflag,'value');
% moveShutter(2,REbit)
% waitforDisplayResp


% --- Executes on button press in LEflag.
function LEflag_Callback(hObject, eventdata, handles)
% hObject    handle to LEflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%mmf
% LEbit = get(handles.LEflag,'value');
% moveShutter(1,LEbit)
% waitforDisplayResp


function monitor_Callback(hObject, eventdata, handles)
% hObject    handle to monitor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global Mstate
    Mstate.monitor = get(handles.monitor, 'string');
    updateMonitorValues
    sendMonitor


% --- Executes during object creation, after setting all properties.
function monitor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to monitor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function stimulusIDP_Callback(hObject, eventdata, handles)
% hObject    handle to stimulusIDP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function stimulusIDP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stimulusIDP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in behavior.
function behavior_Callback(hObject, eventdata, handles)
% hObject    handle to behavior (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in twophotonTog.
function twophotonTog_Callback(hObject, eventdata, handles)
% hObject    handle to twophotonTog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global GUIhandles
    flag = get(handles.twophotonTog, 'value');
    set(GUIhandles.main.twophotonflag, 'value', flag)
    if flag
        set(handles.intrinsicTog, 'value', 0);
        set(GUIhandles.main.intrinsicflag, 'value', 0)
    end

% % --- Executes on button press in twophotonflag.
% function twophotonflag_Callback(hObject, eventdata, handles)
% % hObject    handle to twophotonflag (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% global GUIhandles
% flag = get(handles.twophotonflag,'value');
% set(GUIhandles.main.twophotonflag,'value',flag)
% % if flag
% %     set(handles.intrinsicflag,'value',0);
% %     set(GUIhandles.main.intrinsicflag,'value',0)
% % end


% --- Executes on button press in intrinsicTog.
function intrinsicTog_Callback(hObject, eventdata, handles)
% hObject    handle to intrinsicTog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% --- Executes on button press in intrinsicflag.
    global GUIhandles
    flag = get(handles.intrinsicTog, 'value');
    set(GUIhandles.main.intrinsicflag, 'value', flag)
    if flag
        set(handles.twophotonTog, 'value', 0);
        set(GUIhandles.main.twophotonflag, 'value', 0)
    end

% function intrinsicflag_Callback(hObject, eventdata, handles)
% % hObject    handle to intrinsicflag (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%     global GUIhandles
%     flag = get(handles.intrinsicflag, 'value');
%     set(GUIhandles.main.intrinsicflag, 'value', flag)
%     if flag
%         set(handles.twophotonflag, 'value', 0);
%         set(GUIhandles.main.twophotonflag, 'value', 0)
%     end


% --- Executes on button press in streamTog.
function streamTog_Callback(hObject, eventdata, handles)
% hObject    handle to streamTog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global GUIhandles
    flag = get(handles.streamTog, 'value');
    set(GUIhandles.main.streamFlag, 'value', flag)
    if flag
        set(handles.computef1Tog, 'value', 0);
        set(GUIhandles.main.analysisFlag, 'value', 0)
    end

% % --- Executes on button press in streamFlag.
% function streamFlag_Callback(hObject, eventdata, handles)
% % hObject    handle to streamFlag (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% global GUIhandles
% flag = get(handles.streamFlag,'value');
% set(GUIhandles.main.streamFlag,'value',flag)
% if flag
%     set(handles.analysisFlag,'value',0);
%     set(GUIhandles.main.analysisFlag,'value',0)
% end


% --- Executes on button press in computef1Tog.
function computef1Tog_Callback(hObject, eventdata, handles)
% hObject    handle to computef1Tog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in analysisFlag.
function analysisFlag_Callback(hObject, eventdata, handles)
% hObject    handle to analysisFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global GUIhandles
flag = get(handles.analysisFlag,'value');
set(GUIhandles.main.analysisFlag, 'value', flag)
if flag
    set(handles.analysisFlag, 'value', 0);
    set(GUIhandles.main.analysisFlag, 'value', 0)
end

% --- Executes on button press in LEDtogglebutton.
function LEDtogglebutton_Callback(hObject, eventdata, handles)
% hObject    handle to LEDtogglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of LEDtogglebutton
global GUIhandles daqOUTLED
flag = get(handles.LEDtogglebutton,'value');
set(GUIhandles.main.LEDtogglebutton,'value',flag)
if flag
    outputSingleScan(daqOUTLED, 1)
    set(GUIhandles.main.LEDtogglebutton,'string','LED ON')
else
    outputSingleScan(daqOUTLED, 0)
    set(GUIhandles.main.LEDtogglebutton,'string','LED OFF')
end



