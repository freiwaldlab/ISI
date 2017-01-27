function varargout = imager(varargin)
% IMAGER M-file for imager.fig
%      IMAGER, by itself, creates a new IMAGER or raises the existing
%      singleton*.
%
%      H = IMAGER returns the handle to a new IMAGER or the handle to
%      the existing singleton*.
%
%      IMAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGER.M with the given input arguments.
%
%      IMAGER('Property','Value',...) creates a new IMAGER or raises the
%      existing singleton*.  Starting from the left, property value pairs
%      are
%      applied to the GUI before imager_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property
%      application
%      stop.  All inputs are passed to imager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%% Initialization
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton', gui_Singleton, ...
    'gui_OpeningFcn', @imager_OpeningFcn, ...
    'gui_OutputFcn', @imager_OutputFcn, ...
    'gui_LayoutFcn', [] , ...
    'gui_Callback', []);

if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

%% Executes just before imager is made visible
function imager_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imager (see VARARGIN)

%% Settings
global IMGSIZE FPS;
%FPS = 10; % We can't set this here. see below mmf

% Data directory, unit, and tag settings
handles.datatxt = 'c:\imager_data\xx0';
handles.unit = 'u000_000';
handles.time_tag = 0;

%%% DEBUG XXX ***
handles

%%  Camera communication
% https://www.mathworks.com/help/imaq/basic-image-acquisition-procedure.html

%%% DEBUG XXX *** is this necessary now?
%delete(instrfind) %don't think so. 

% Establish connection with PointGrey camera and set mode
handles.vid = videoinput('pointgrey', 1, 'F7_Raw16_1920x1200_Mode0');
handles.vid.TriggerRepeat = Inf;
handles.vid.FramesPerTrigger = Inf;
%vid.FrameGrabInterval = 2; % Dependent on the mode selected & memory
%available.  Will try without setting this, but if need be, we can select
%only every nth frame. mmf

% Define video source
handles.src = getselectedsource(handles.vid);
handles.src.Tag = 'ISI';
FPS = handles.src.FrameRate;

%% Establish illumination control
% NOTE: If we want to control the illumination ring led on/off through
% MATLAB, need to have another USB Daq to run this. Otherwise, we cannot
% simultaneously run clocked operations

% Prepare illuminator control through serial
% sit = serial('COM2','Tag','ilser','Terminator','CR','DataTerminalReady',...
%     'off','RequestToSend','off');
% fopen(sit);
% handles.sit = sit;

%% Set up audio output for tracking master-slave communication

handles.blip = audioplayer(10 * sin(linspace(0, 2 * pi, 32)), 30000);

%% Set up ActiveX handles
% NOTE: Disabled in transition to new MATLAB and away from MIL.

% handles.milapp = handles.activex25;
% handles.mildig = handles.activex24;
% handles.mildisp = handles.activex23;
% handles.milimg = handles.activex26;
% handles.milsys = handles.activex27;
% handles.milsys.Allocate;  % Allocate MIL system

%mmf testing
handles.milapp = {};
handles.mildig = {};
handles.mildisp = {};
handles.milimg = {};
handles.milsys = {};

% From miltest.m, for reference:
% milapp = actxcontrol('MIL.Application');
% milsys = actxcontrol('MIL.System');
% mildisp = actxcontrol('MIL.Display',[10 10 800 800]);
% mildig = actxcontrol('MIL.Digitizer');
% milimg = actxcontrol('MIL.Image');

%% Set up display of video

%%% XXX *** needs to be set up
% mmf... this is not right, but testing for fun.
% https://www.mathworks.com/matlabcentral/answers/96242-how-can-i-insert-live-video-into-a-matlab-gui-using-image-acquisition-toolbox
% handles.mildisp.set('OwnerSystem',handles.milsys,...
%    'DisplayType','dispActiveMILWindow');
%handles.mildisp.Allocate
% handles.mildisp.OwnerSystem = handles.milsys; %these are currently empty
% handles.mildisp.DisplayType = 'dispActiveMILWindow';
%
%handles.mildig.set('OwnerSystem',handles.milsys,'GrabFrameEndEvent',0,...
%    'GrabFrameStartEvent',0,'GrabStartEvent',0,'GrabEndEvent',0,...
%    'GrabMode','digAsynchronousQueue');
%not sure we need any of these either... mmf
% handles.mildig.OwnerSystem = handles.milsys;


%% Ian code...
global ROIcrop

%%% XXX *** should already be configured via videoinput
%mmf therefore don't need
% handles.mildig.set('Format','C:\imager\2x2bin_dlr.dcf');  %Preset the binning to 2x2
% y = clsend('sbm 2 2');
% handles.mildig.Allocate;

% Get size and initialize ROI to full size
IMGSIZE = handles.vid.VideoResolution;
Xpx = IMGSIZE(1);
Ypx = IMGSIZE(2);
ROIcrop = [0 0 Xpx Ypx];

%%% XXX *** needs to be set up 
% mmf - we might not even need this: it's all saved in vid/src
% handles.milimg.set('CanGrab',1,'CanDisplay',1,'CanProcess',0, ...
%    'SizeX',Xpx,'SizeY',Ypx,'DataDepth',16,'NumberOfBands',1, ...
%    'OwnerSystem',handles.milsys);
% handles.milimg.Allocate;
% handles.mildig.set('Image',handles.milimg);
% handles.mildisp.set('Image',handles.milimg,'ViewMode',...
%    'dispBitShift','ViewBitShift',4);

%% Set up buffers
global NBUF;
NBUF = 2;

%%% XXX *** needs to be set up 
%do we need this? mmf
% for i = 1:NBUF
% %    handles.buf{i} = actxcontrol('MIL.Image',[0 0 1 1]);
% %    handles.buf{i}.set('CanGrab',1,'CanDisplay',0,'CanProcess',0, ...
% %        'SizeX',Xpx,'SizeY',Ypx,'DataDepth',16,'NumberOfBands',1, ...
% %        'FileFormat','imRaw','OwnerSystem',handles.milsys);
% %    
% %        % The child images
% %        handles.child{i} = actxcontrol('MIL.Image',[0 0 1 1]);
% %        set(handles.child{i},'ParentImage',handles.buf{i},'AutomaticAllocation',1);
% %        set(handles.child{i}.ChildRegion,'OffsetX',256);
% %        set(handles.child{i}.ChildRegion,'OffsetY',256);
% %        set(handles.child{i}.ChildRegion,'SizeX',128);
% %        set(handles.child{i}.ChildRegion,'SizeY',128);
% %        handles.buf{i}.Allocate;
% end

%% Construct a timer

handles.timer = timer;
set(handles.timer, 'Period', 0.5, 'BusyMode', 'drop', 'ExecutionMode', ...
    'fixedSpacing', 'TimerFcn', @timerhandler)

%% Set up either display or something else - mmf: i think this is just for the heatmap?? 

global imagerhandles;

%%% DEBUG XXX *** not sure what is happening here
imagerhandles = handles; % we need this for the timerfcn callback
imagerhandles.roi = [256 256];
imagerhandles.roisize = 100;
imagerhandles.hwroi = [256 256]; % Center of the image data region of interest (assumes 2x2 binning)
imagerhandles.hwroisize = 128;

% Choose default command line output for imager
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%% --- Outputs from this function are returned to the command line.
function varargout = imager_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% --- Executes on button press in Grab.
function Grab_Callback(hObject, eventdata, handles)
% hObject    handle to Grab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(get(hObject,'Value'))
    start(handles.timer);
else
    stop(handles.timer);
end

%% --- Executes on slider movement.
function pany_Callback(hObject, eventdata, handles)
% hObject    handle to pany (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% mmf. this is a mystery.  commented it out for now.
% px = get(handles.panx,'Value');
% py = get(handles.pany,'Value');
%%% DEBUG XXX *** how to do this with videoinput?
% handles.mildisp.Pan(px,-py);



%% --- Executes during object creation, after setting all properties.
function pany_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pany (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor', [.9 .9 .9]);
else
    set(hObject,'BackgroundColor', get(0, 'defaultUicontrolBackgroundColor'));
end

%% --- Executes on slider movement.
function panx_Callback(hObject, eventdata, handles)
% hObject    handle to panx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% mmf. yeah.
% px = get(handles.panx,'Value');
% py = get(handles.pany,'Value');
%%% DEBUG XXX *** how to do this with videoinput?
%handles.mildisp.Pan(px,-py);

%% --- Executes during object creation, after setting all properties.
function panx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',...
        get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes during object creation, after setting all properties.
function zoom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background, change
%       'usewhitebg' to 0 to use default.  See ISPC and COMPUTER.
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',...
        get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
contents = get(hObject,'String');
z = str2double(contents{get(hObject, 'Value')});
%%% DEBUG XXX *** how to do this with videoinput?
%handles.mildisp.ZoomX = z;
%handles.mildisp.ZoomY = z;

%% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',...
        get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on button press in histbox.
function histbox_Callback(hObject, eventdata, handles)
% hObject    handle to histbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of histbox

%%
%%% XXX *** remove?
% We are not using this handler any more...
% function dighandler(varargin)
% global imagerhandles nframes T;
% 
% imagerhandles.mildig.Image = imagerhandles.buf{bitand(nframes,1)+1};  %% switch buffer
% T(nframes+1)=invoke(imagerhandles.milapp.Timer,'Read')
% nframes = nframes+1
% if(nframes>20)
%     imagerhandles.mildig.Halt;
%     imagerhandles.mildig.set('GrabFrameEndEvent',0);
% end

%% --- Executes on button press in autoscale.
function autoscale_Callback(hObject, eventdata, handles)
% hObject    handle to autoscale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autoscale

% mmf do we even need this function anymore?
if(get(hObject,'Value'))
    %%% XXX *** do this with videoinput
    %handles.mildisp.set('ViewMode','dispAutoScale')
else
    %%% XXX *** do this with videoinput
    %handles.mildisp.set('ViewMode','dispBitShift','ViewBitShift',4);
end

%% 
function timerhandler(varargin)
global imagerhandles IMGSIZE;

Xpx = IMGSIZE(1);
Ypx = IMGSIZE(2);

%%% XXX *** can do this with videoinput?  even worth it?
% get the temperature...
% y = clsend('vt');
% if(length(y)>10)
%     idx = findstr(y,'Celsius');
%     t1 = y(idx(1)-5:idx(1)-2);
%     t2 = y(idx(2)-5:idx(2)-2);
% else 
%     t1 = 0;
%     t2 = 0;
% end

%%% XXX *** do this with videoinput
h = imagerhandles;
%h.mildig.Grab;

% set(h.temptxt,'String',sprintf('Digitizer: %sC  Sensor: %sC',t1,t2));

%% Check for saturation
%%% DEBUG XXX ***
get(h.histbox, 'Value')
if (get(h.histbox, 'Value')) % Analyze?

    jetmap = jet;
    jetmap(end-2:end,:) = 1;
    colormap(jetmap);
    axes(h.jetaxis);
    cla;
    zz = zeros(Xpx,Ypx,'uint16');
    
    %%% XXX *** do this with videoinput ... probably snapshot
    getsnapshot(h.vid);
    %h.mildig.GrabWait(3); % wait...
    % from mil.h
    % #define M_GRAB_NEXT_FRAME                             1L
    % #define M_GRAB_NEXT_FIELD                             2L
    % #define M_GRAB_END                                    3L

    xmin = max(1, ceil(h.roi(1)-h.roisize/2));
    xmax = min(Xpx, floor(h.roi(1)+h.roisize/2));
    ymin = max(1, ceil(h.roi(2)-h.roisize/2));
    ymax = min(Ypx, floor(h.roi(2)+h.roisize/2));
        
    [xx, yy] = meshgrid(xmin:xmax,ymin:ymax);
    I = sub2ind([Xpx Ypx],xx(:),yy(:));
        
    imagerhandles.roiI = I;
    
    %%% XXX *** do this with videoinput ... probably snapshot
    %img = h.milimg.Get(zz,IMGSIZE^2,-1,0,0,IMGSIZE,IMGSIZE);
    %%% XXX *** pull bitdepth from ptgrey
    img = getsnapshot(h.vid);
    image((double(img)' / 4096) * 64);
    %image(img);
    axis ij;
    hold on;
    plot([xmin xmax xmax xmin xmin], [ymin ymin ymax ymax ymin], ...
        'k-', 'linewidth', 2);
    
    %% Now the image ROI
    xmin = max(1,ceil(h.hwroi(1)-h.hwroisize/2));
    xmax = min(Xpx,floor(h.hwroi(1)+h.hwroisize/2));
    ymin = max(1,ceil(h.hwroi(2)-h.hwroisize/2));
    ymax = min(Ypx,floor(h.hwroi(2)+h.hwroisize/2));
            
    plot([xmin xmax xmax xmin xmin], [ymin ymin ymax ymax ymin], ...
        'c:','linewidth',2);
    hold off;
    axis off;

    axes(h.cmapaxes);
    cla;
    colormap(jetmap);
    image(1:64);
    axis off;

    axes(h.histaxes); cla;
    %%% XXX *** pull bitdepth from ptgrey
    %hist(img(I),32:64:4096);
    imhist(img)   
    box off;
    %set(gca,'ytick',[],'xtick',[0:1024:4096],'xlim',[0 4096],'fontsize',8);
    
    %%% XXX *** pull bitdepth from ptgrey
    %set(h.focustxt,'String',sprintf('Focus: %.2f',100*focval(img)));
end

%% Send to camera over serial com
%%% XXX *** remove when no longer used
function y = clsend(str)
disp('fool, that camera link stuff doesnt exist')
disp(str)
% scl = instrfind('Tag','clser');
% if(~isempty(scl))
%     fprintf(scl,'%s\n',str);
%     pause(0.05);
%     N = get(scl,'BytesAvailable');
%     y = [];
%     while(N>0)
%         y = [y char(fread(scl,N,'char')')];
%         pause(0.05);
%         N = get(scl,'BytesAvailable');
%     end
% else
%     y = '\n Error>> No message from camera!\n';
% end

%% Send command to illuminator
function y = itsend(str)
disp('fool, that itsend stuff doesnt exist')
disp(str)
% sit = instrfind('Tag','ilser');
% if(~isempty(sit))
%     fwrite(sit,[str 13]);
%     pause(0.05);
%     N = get(sit,'BytesAvailable');
%     if(N>0)
%         y = fgetl(sit);
%     end
% else
%     y = '\n Error>> No message from camera!\n';
% end

%%% XXX *** remove if no longer used
%mmf mystery.
function r = parsepr(y)
tail = y;
[head,tail] = strtok(tail,[10 13]);
r.quality = head;
[head,tail] = strtok(tail,[10 13]);
r.ii = head;
k = 1;
while(length(tail)>0)
    [head,tail] = strtok(tail,[10 13]);
    r.meas{k} = sscanf(head,'%f,%f');
    k = k+1;
end

%% Measure spectrum with PR instrument
function y = prmeasure
spr = instrfind('Tag','prser');
if(~isempty(spr))
    fwrite(spr,['M5' 13]);
    N = get(spr,'BytesAvailable');
    while(spr.BytesAvailable<1734)    %% wait for measurement to end
    end
    y = char(fread(spr,spr.BytesAvailable))';
else
    warning('Problem measuring spectrum with PR instrument');
    y = 'Problem';
end

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double

s = get(hObject,'String');
cmd = s(end,:);  %% get last line
%%% XXX *** update if needed
y = clsend(cmd);
s = str2mat(cmd,y);
set(hObject,'String',s);

%% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',...
        get(0,'defaultUicontrolBackgroundColor'));
end

%% Focus value function
function y = focval(q)
% Calculate coefficient of variation
global imagerhandles
x = double(q(imagerhandles.roiI));
y = std(x) / mean(x);

% Alternatively, calculate power
% global IMGSIZE
% delta = round(IMGSIZE/256);
% f = fftshift(abs(fft2(double(q(1:delta:end,1:delta:end))))).^2; % power spectrum
% [xx,yy] = meshgrid(-127:128,-127:128);
% mask = (xx.^2+yy.^2)>20^2;
% y = sum(sum((mask.*f)))./sum(sum(f));

%% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2

idx = get(hObject,'Value');
switch(idx)
    case 1 % stopped
        %%% XXX *** update to videoinput stop()
        handles.mildig.Halt;
        stop(handles.timer);
        handles.mildig.set('GrabEndEvent',0,'GrabStartEvent',0);
        handles.mildig.Image = handles.milimg;  %% restore image
    case 2 % grab continuous
        %%% XXX *** update to videoinput
        handles.mildig.Image = handles.milimg;  %% restore image
        stop(handles.timer);
        handles.mildig.set('GrabEndEvent',0,'GrabStartEvent',0);
        handles.mildig.GrabContinuous;
    case 3 % adjust illumination
        %%% XXX *** update 
        handles.mildig.Image = handles.milimg;  %% restore image
        handles.mildig.Halt;
        handles.mildig.set('GrabEndEvent',0,'GrabStartEvent',0);
        start(handles.timer);
    case 4 % ?
        %%% XXX *** update to videoinput
        handles.mildig.Halt;
        stop(handles.timer);
        handles.mildig.set('GrabEndEvent',0,'GrabStartEvent',0);
        handles.milimg.Load('tv.raw',0);
end

%% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%
function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to datatxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of datatxt as text
%        str2double(get(hObject,'String')) returns contents of datatxt as a double

%% --- Executes during object creation, after setting all properties.
function datatxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datatxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%
function unittxt_Callback(hObject, eventdata, handles)
% hObject    handle to unittxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of unittxt as text
%        str2double(get(hObject,'String')) returns contents of unittxt as a double

%% --- Executes during object creation, after setting all properties.
function unittxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to unittxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%
function tagtxt_Callback(hObject, eventdata, handles)
% hObject    handle to tagtxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagtxt as text
%        str2double(get(hObject,'String')) returns contents of tagtxt as a double

%% --- Executes during object creation, after setting all properties.
function tagtxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagtxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global imagerhandles;
dir = uigetdir('','Select data directory');
if(dir~=0)
    imagerhandles.datadir = dir;
    set(findobj('Tag','datatxt'),'String',dir);
end

%%
function expttxt_Callback(hObject, eventdata, handles)
% hObject    handle to expttxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of expttxt as text
%        str2double(get(hObject,'String')) returns contents of expttxt as a double

%% --- Executes during object creation, after setting all properties.
function expttxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to expttxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%
function animaltxt_Callback(hObject, eventdata, handles)
% hObject    handle to animaltxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of animaltxt as text
%        str2double(get(hObject,'String')) returns contents of animaltxt as a double

%% --- Executes during object creation, after setting all properties.
function animaltxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to animaltxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%
function timetxt_Callback(hObject, eventdata, handles)
% hObject    handle to timetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timetxt as text
%        str2double(get(hObject,'String')) returns contents of timetxt as a double

%% --- Executes during object creation, after setting all properties.
function timetxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%
function cltext_Callback(hObject, eventdata, handles)
% hObject    handle to cltext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cltext as text
%        str2double(get(hObject,'String')) returns contents of cltext as a double

%%% XXX *** update to videoinput
disp('you tried to send something to the camera... fail')
disp(get(hObject,'String'))
% y = clsend(get(hObject,'String'));
% set(handles.clreply,'String',y);

%% --- Executes during object creation, after setting all properties.
function cltext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cltext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on selection change in streampop.
function streampop_Callback(hObject, eventdata, handles)
% hObject    handle to streampop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns streampop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from streampop

%% --- Executes during object creation, after setting all properties.
function streampop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to streampop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%%
function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double

%% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on button press in memorybox.
function memorybox_Callback(hObject, eventdata, handles)
% hObject    handle to memorybox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%
function framerate_Callback(hObject, eventdata, handles)
% hObject    handle to framerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global FPS
%%% XXX *** update to videoinput
FPS = str2num(get(hObject,'String'));
disp(get(hObject,'String'))
%y = clsend(sprintf('ssf %d',round(FPS)));

%% --- Executes during object creation, after setting all properties.
function framerate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to framerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on selection change in binning.
function binning_Callback(hObject, eventdata, handles)
% hObject    handle to binning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global IMGSIZE;
%%% XXX *** update to videoinput (close and reopen or change mode?)
idx = get(hObject,'Value');
set(1,'Name','imager :: PLEASE WAIT! ::');
drawnow;
handles.mildig.Free;
switch(idx)
    case 1     % 1x1
        handles.mildig.set('Format','C:\imager\1x1bin_dlr.dcf');
        y = clsend('sbm 1 1');
    case 2     % 2x2
        handles.mildig.set('Format','C:\imager\2x2bin_dlr.dcf');
        y = clsend('sbm 2 2');
    case 3     % 4x4
        handles.mildig.set('Format','C:\imager\4x4bin_dlr.dcf');
        y = clsend('sbm 4 4');
    case 4     % 8x8
        handles.mildig.set('Format','C:\imager\8x8bin_dlr.dcf');
        y = clsend('sbm 8 8');
end
%%% XXX *** update
handles.mildig.Allocate;  % allocate
IMGSIZE = handles.mildig.get('SizeX') % get the new size
%%% XXX *** update
handles.milimg.Free;  %% Free the image and change its size
handles.milimg.set('CanGrab',1,'CanDisplay',1,'CanProcess',0, ...
    'SizeX',IMGSIZE,'SizeY',IMGSIZE,'DataDepth',16,'NumberOfBands',1, ...
    'OwnerSystem',handles.milsys);
%%% XXX *** update
handles.milimg.Allocate; %% allocate again...
%%% XXX *** update
handles.mildig.set('Image',handles.milimg);
handles.mildisp.set('Image',handles.milimg,'ViewMode','dispBitShift','ViewBitShift',4);

% Update buffers
global NBUF;

for i = 1:NBUF
    %%% XXX *** update
    handles.buf{i}.Free;  %% Free the buffer... and change its size
    handles.buf{i}.set('CanGrab',1,'CanDisplay',0,'CanProcess',0, ...
        'SizeX',IMGSIZE,'SizeY',IMGSIZE,'DataDepth',16,'NumberOfBands',1, ...
        'FileFormat','imRaw','OwnerSystem',handles.milsys);
    handles.buf{i}.Allocate;  %% re-allocate
end
set(1,'Name','imager');
drawnow;

%% --- Executes during object creation, after setting all properties.
function binning_CreateFcn(hObject, eventdata, handles)
% hObject    handle to binning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on button press in adjustlight.
function adjustlight_Callback(hObject, eventdata, handles)
% hObject    handle to adjustlight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('Increase light so that histogram within ROI just reaches saturation')
disp('Focus')
disp('repeat the above 2-3 times...')

%% --- Executes on selection change in panelcontrol.
function panelcontrol_Callback(hObject, eventdata, handles)
% hObject    handle to panelcontrol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns panelcontrol contents as cell array
%        contents{get(hObject,'Value')} returns selected item from panelcontrol

switch(get(hObject,'value'))
    case 1
%         setvis(handles.panel1,'on');
%         setvis(handles.panel2,'off');
%         setvis(handles.panel3,'off');
%         setvis(handles.Radiometer,'off');
% This used to work in R14 SP2 and then stopped working in R14 SP3 that's
% why I wrote the setvis() workaround above...

%%% XXX *** check to see if this works
        set(handles.panel1,'Visible','on');
        set(handles.panel2,'Visible','off');
        set(handles.panel3,'Visible','off');
        set(handles.Radiometer,'Visible','off');
    case 2
%         setvis(handles.panel1,'off');
%         setvis(handles.panel2,'on');
%         setvis(handles.panel3,'off');
%         setvis(handles.Radiometer,'off');
%%% XXX *** check to see if this works
        set(handles.panel1,'Visible','off');
        set(handles.panel2,'Visible','on');
        set(handles.panel3,'Visible','off');
        set(handles.Radiometer,'Visible','off');
    case 3
%         setvis(handles.panel1,'off');
%         setvis(handles.panel2,'off');
%         setvis(handles.panel3,'on');
%         setvis(handles.Radiometer,'off'); 
%%% XXX *** check to see if this works
        set(handles.panel1,'Visible','off');
        set(handles.panel2,'Visible','off');
        set(handles.panel3,'Visible','on');
        set(handles.Radiometer,'Visible','off');
    case 4
%         setvis(handles.panel1,'off');
%         setvis(handles.panel2,'off');
%         setvis(handles.panel3,'off');
%         setvis(handles.Radiometer,'on');
%%% XXX *** check to see if this works
        set(handles.panel1,'Visible','off');
        set(handles.panel2,'Visible','off');
        set(handles.panel3,'Visible','off');
        set(handles.Radiometer,'Visible','on');
end

%%% XXX *** check to see if this is needed
function setvis(handle,state)
list = allchild(handle);
for(j=1:length(list))
    set(list(j),'Visible',state);
end
set(handle,'Visible',state);

%% --- Executes during object creation, after setting all properties.
function panelcontrol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panelcontrol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on slider movement.
function setlight_Callback(hObject, eventdata, handles)
% hObject    handle to setlight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = round(get(hObject,'Value'));
disp('please adjust manually')
disp(val)
%%% XXX *** update if illumination can be controlled by computer
%itsend(sprintf('DAC=%03d',val));

%% --- Executes during object creation, after setting all properties.
function setlight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setlight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on button press in itpower.
function itpower_Callback(hObject, eventdata, handles)
% hObject    handle to itpower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject,'Value');
disp('please adjust manually')
disp(val)
%%% XXX *** update if illumination can be controlled by computer
%itsend(['SSR=' num2str(val)]);

%% --- Executes on button press in ttlpulse.
function ttlpulse_Callback(hObject, eventdata, handles)
% hObject    handle to ttlpulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles;
% Play audio blip that serves as a sync pulse
playblocking(imagerhandles.blip);

%%
function itime_Callback(hObject, eventdata, handles)
% hObject    handle to itime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% --- Executes during object creation, after setting all properties.
function itime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to itime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%% --- Executes on button press in prinit.
function prinit_Callback(hObject, eventdata, handles)
% hObject    handle to prinit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('prinit disabled')
%%% XXX *** not sure what this is doing.. maybe GUI will inform
% spr = instrfind('Tag','prser');
% if(~isempty(spr))
%     val = round(str2num(get(findobj('Tag','itime'),'String'))*100);
%     fwrite(spr,[sprintf('S,,,,,%d,1,1',val) 13]);
%     pause(0.5);
%     N = get(spr,'BytesAvailable');
%     y = char(fread(spr,spr.BytesAvailable))';
% else
%     warning('Problem initializing the PR instrument');
%     y = 'Problem';
% end
% y

%% --- Executes on button press in prmeasure.
function prmeasure_Callback(hObject, eventdata, handles)
% hObject    handle to prmeasure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
y = prmeasure;

%% --- Executes on button press in grabimage.
function grabimage_Callback(hObject, eventdata, handles)
% hObject    handle to grabimage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles ROIcrop

img = zeros(ROIcrop(3), ROIcrop(4), 'uint16');
%%% XXX *** update for videoinput
%img = imagerhandles.milimg.Get(zz,IMGSIZE^2,-1,ROIcrop(1),ROIcrop(2),ROIcrop(3),ROIcrop(4));

grab.img = img;
% Time stamp
grab.clock = clock;
grab.ROIcrop = ROIcrop;
figure(10);
imagesc(grab.img')
axis off
colormap gray
truesize
r = questdlg('Do you want to save it?', ...
    'Single Grab', 'Yes', 'No', 'Yes');
if(strcmp(r,'Yes'))
    grab.comment = inputdlg('Please enter description:', ...
        'Image Grab', 1, {'No description'}, 'on');
    animal = get(findobj('Tag', 'animaltxt'), 'String');
    unit = get(findobj('Tag', 'unittxt'), 'String');
    expt = get(findobj('Tag', 'expttxt'), 'String');
    datadir = get(findobj('Tag', 'datatxt'), 'String');
    tag = get(findobj('Tag', 'tagtxt'), 'String');

    dd = strcat(datadir, filesep, animal, filesep, 'grabs', filesep);
    if ~exist(dd, 'dir')
        mkdir(dd);
    end
    fname = strcat(dd, 'grab_', datestr(now, 'yyyymmddtHHMMSSpFFF'), ...
        get(imagerhandles.animaltxt, 'String'), '_', ...
        get(imagerhandles.unittxt, 'String'), '_', ...
        get(imagerhandles.expttxt, 'String'));
    fname = strrep(fname, ' ', '_');
    fname(3:end) = strrep(fname(3:end), ':', '_');
    fname = strrep(fname, '-', '');
    fname = strcat(fname, '.mat');
    %%% XXX *** update for videoinput
    save(fname, 'grab');
end
delete(10);

%% --- Executes on button press in pushbutton17.
function pushbutton17_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global running;
running = 0;

%% --- Executes on mouse press over axes background.
function jetaxis_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to jetaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% --- Executes on button press in roibutton.
function roibutton_Callback(hObject, eventdata, handles)
% hObject    handle to roibutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles;
h = imagerhandles;
stop(h.timer);
axes(h.cmapaxes);
imagerhandles.roi = ginput(1);
start(h.timer);

%% --- Executes during object creation, after setting all properties.
function zaxis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% --- Executes on slider movement.
function zaxis_Callback(hObject, eventdata, handles)
% hObject    handle to zaxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = round(get(hObject,'Value')); % z-axis position
zaxis_absolute(val); % move to this absolute value
disp('hi, which slider am I?')

%%
function roisize_Callback(hObject, eventdata, handles)
% hObject    handle to roisize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles;
%%% XXX *** square only?
imagerhandles.roisize = round(str2double(get(hObject,'String')));
% h = imagerhandles;
% tmr_sts = h.timer.running;
% stop(tmr_sts);
% xmin = max(1,ceil(h.roi(1)-h.roisize/2));
% xmax = min(IMGSIZE,floor(h.roi(1)+h.roisize/2));
% ymin = max(1,ceil(h.roi(2)-h.roisize/2));
% ymax = min(IMGSIZE,floor(h.roi(2)+h.roisize/2));
% [xx,yy] = meshgrid(xmin:xmax,ymin:ymax);
% I = sub2ind([IMGSIZE IMGSIZE],xx(:),yy(:));
% imagerhandles.roiI = I;
% if(strcmp(tmr_sts,'on'))
%     start(h.timer);
% end

%% --- Executes during object creation, after setting all properties.
function roisize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roisize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%
function zaxis_absolute(pos)
disp('No Z-axis present, please adjust manually')
% global imagerhandles;
% sza = imagerhandles.sza;
% fwrite(sza,[sprintf('4 LA %d',pos) 13 10]); % Set absolute position
% fwrite(sza,['4 M' 13 10]); % Move

%% --- Executes on button press in zaxenable.
function zaxenable_Callback(hObject, eventdata, handles)
% hObject    handle to zaxenable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('No Z-axis present, please adjust manually')
% global imagerhandles;
% sza = imagerhandles.sza;
% if(get(hObject,'Value'))
%     fwrite(sza,['4 EN' 13 10]); % enable
% else
%     fwrite(sza,['4 DIS' 13 10]); % disable
% end

%%
function smarthome(dev,action)
disp('No Z-axis present, please adjust manually')
% s = instrfind('Tag','x10');
% switch(dev)
%     case 'camera'
%         id = '46';
%     case 'motor'
%         id = '4E';
%     otherwise
%         warning('No such X10 device')
%         return;
% end
% switch(action)
%     case 1
%         code = '45';
%     case 0
%         code = '47';
%     otherwise
%         warning('No such X10 action');
%         return;
% end
% fwrite(s,hex2dec({'02' '63' id '4C' code '41'}),'char');
% if(s.BytesAvailable > 0)
%     fread(s,s.BytesAvailable);
% end

%% --- Executes on button press in checkbox8.
function checkbox8_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
smarthome('camera',get(hObject,'Value'));

%% --- Executes on selection change in popupmenu9.
function popupmenu9_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% --- Executes during object creation, after setting all properties.
function popupmenu9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%
function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% --- Executes on button press in selectROI.
function selectROI_Callback(hObject, eventdata, handles)
% hObject    handle to selectROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles IMGSIZE ROIcrop;
Xpx = IMGSIZE(1);
Ypx = IMGSIZE(2);

% img = zeros(Xpx, Ypx, 'uint16'); %%% XXX *** should be unnecessary
zz  = zeros(Xpx, Ypx, 'uint16');
%%% XXX *** update for videoinput
img = imagerhandles.milimg.Get(zz,IMGSIZE^2,-1,0,0,IMGSIZE,IMGSIZE)'; % grab last one

figure(10);
imagesc(img),axis off, colormap gray; truesize

r = questdlg('Crop the image that is saved to the disk?','Select ROI','Yes','No','Yes');
if(strcmp(r,'Yes'))
    [I2, ROIcrop] = imcrop;
    ROIcrop = round(ROIcrop);
end
close(10)
%%% XXX *** make slightly more standard / elegant
save('C:\Dropbox\Goeppert-Mayer\ISI\imager\lastROI', 'ROIcrop')

%%
function hwroisizetxt_Callback(hObject, eventdata, handles)
% hObject    handle to hwroisizetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global imagerhandles;
h = imagerhandles;
stop(h.timer);
axes(h.cmapaxes);
imagerhandles.hwroisize = str2double(get(h.hwroisizetxt,'String'));
update_hwroi;
start(h.timer);

%% --- Executes during object creation, after setting all properties.
function hwroisizetxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hwroisizetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%
function update_hwroi
global imagerhandles;
for i = 1:2
    set(imagerhandles.child{i}.ChildRegion,'OffsetX',round(imagerhandles.hwroi(1) - imagerhandles.hwroisize/2));
    set(imagerhandles.child{i}.ChildRegion,'OffsetY',round(imagerhandles.hwroi(2) - imagerhandles.hwroisize/2));
    set(imagerhandles.child{i}.ChildRegion,'SizeX',imagerhandles.hwroisize);
    set(imagerhandles.child{i}.ChildRegion,'SizeY',imagerhandles.hwroisize);
end

%% --- Executes on button press in resetCrop.
function resetCrop_Callback(hObject, eventdata, handles)
% hObject    handle to resetCrop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IMGSIZE ROIcrop
Xpx = IMGSIZE(1);
Ypx = IMGSIZE(2);
ROIcrop = [0 0 Xpx Ypx];

%% --- Executes on button press in getLastROI.
function getLastROI_Callback(hObject, eventdata, handles)
% hObject    handle to getLastROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ROIcrop
%%% XXX *** make slightly more standard / elegant
load('C:\Dropbox\Goeppert-Mayer\ISI\imager\lastROI', 'ROIcrop')
ROIcrop