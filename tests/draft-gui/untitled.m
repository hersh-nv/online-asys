function varargout = untitled(varargin)
% UNTITLED MATLAB code for untitled.fig
%      UNTITLED, by itself, creates a new UNTITLED or raises the existing
%      singleton*.
%
%      H = UNTITLED returns the handle to a new UNTITLED or the handle to
%      the existing singleton*.
%
%      UNTITLED('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UNTITLED.M with the given input arguments.
%
%      UNTITLED('Property','Value',...) creates a new UNTITLED or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before untitled_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to untitled_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help untitled

% Last Modified by GUIDE v2.5 24-Apr-2018 11:18:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @untitled_OpeningFcn, ...
                   'gui_OutputFcn',  @untitled_OutputFcn, ...
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


% --- Executes just before untitled is made visible.
function untitled_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to untitled (see VARARGIN)

% Choose default command line output for untitled
handles.output = hObject;
set(handles.rasterAxes,'YTick',[]);

handles.minCh = 33;
handles.maxCh = 64;
handles.nRep  = 20;  % maximum number of stimuli repetitions for each type
handles.sampling_freq = 30000;
handles.tmin  = 0;
handles.tmax  = 1;
handles.IDreps = [];             % num of recorded reps per IDtype
handles.plottedTrialNo = [];
handles.spikebuffer{handles.maxCh,1}=[];
handles.cmtbuffer = [];
handles.cmttimesbuffer = [];
handles.trialdata={};
handles.selCh = handles.minCh;
handles.pullUpdatePeriod = 0.25;     % how often to pull spike data     
handles.populateUpdatePeriod = 1;   % how often to populate trial-aligned spike array with pull data
handles.drawUpdatePeriod = 2;       % how often to update figures


% Update handles structure
guidata(hObject, handles);

% Initial configurations

% UIWAIT makes untitled wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = untitled_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in startStreamButton.
function startStreamButton_Callback(hObject, eventdata, handles)

% === replace this with call to open CBMEX; return success or error status
pressed = get(hObject,'Value');
if (pressed)
    err=startStream(gcbo,handles);
    % print status message and update toggle button label
    if (~err)   
        set(handles.streamStatusText,'ForegroundColor',[0.4 0.8 0.4]);
        set(handles.streamStatusText,'String','CBMEX open');
        set(handles.startStreamButton,'String','Stop CBMEX');
    else        
        set(handles.streamStatusText,'ForegroundColor',[0.8 0.4 0.4]);
        set(handles.streamStatusText,'String','CBMEX failed');
        set(handles.startStreamButton,'String','Start CBMEX');
        set(hObject,'Value',0);
    end
else
    stopStream();
    set(handles.streamStatusText,'ForegroundColor',[0 0 0]);
    set(handles.streamStatusText,'String','CBMEX closed');
    set(handles.startStreamButton,'String','Start CBMEX');
end



function channelNo_Callback(hObject, eventdata, handles)
% hObject    handle to channelNo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
inCh = str2double(get(hObject,'String'));
if (isnumeric(inCh) && inCh >= handles.minCh && inCh < handles.maxCh)
    handles.selCh = inCh;
    disp(handles.selCh);

    % reset figure (will be automatically repopulated on next rasterUpdate)
    cla(handles.rasterAxes);
    handles.plottedTrialNo = [];

    guidata(hObject,handles);
else
    disp('Input valid channel number');
end
% Hints: get(hObject,'String') returns contents of channelNo as text
%        str2double(get(hObject,'String')) returns contents of channelNo as a double



% --- Executes during object creation, after setting all properties.
function channelNo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelNo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'String',handles.selCh);
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function rasterAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rasterAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
disp('rasterAxes created');

% Hint: place code in OpeningFcn to populate rasterAxes

function rasterAxes_OpeningFcn(hObject, eventdata, handles)
disp('rasterAxes opened');


% --- Executes on button press in plotButton.
function plotButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% timer 3
% rasterStart(hObject);
handles.drawTimer=timer('Period',handles.drawUpdatePeriod,...
    'TimerFcn',{@rasterUpdate,hObject},...
    'ExecutionMode','fixedSpacing'...
    );
start(handles.drawTimer);
guidata(hObject, handles);



function tminInput_Callback(hObject, eventdata, handles)
% hObject    handle to tminInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
input = str2double(get(hObject,'String'));
if (isnumeric(input) && input>=0 && input<handles.tmax)
    handles.tmin = input;

    axes(handles.rasterAxes)
    xlim([handles.tmin,handles.tmax]);
    
    disp('tmin saved');
    guidata(hObject,handles);
else
    disp('Invalid tmin');
end

% Hints: get(hObject,'String') returns contents of tminInput as text
%        str2double(get(hObject,'String')) returns contents of tminInput as a double


% --- Executes during object creation, after setting all properties.
function tminInput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tminInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tmaxInput_Callback(hObject, eventdata, handles)
% hObject    handle to tmaxInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
input = str2double(get(hObject,'String'));
if (isnumeric(input) && input>0 && input>handles.tmin)
    handles.tmax = input;
    disp('tmax saved');
    
    axes(handles.rasterAxes)
    xlim([handles.tmin,handles.tmax]);
    
    guidata(hObject,handles);
else
    disp('Invalid tmax');
end

% Hints: get(hObject,'String') returns contents of tmaxInput as text
%        str2double(get(hObject,'String')) returns contents of tmaxInput as a double


% --- Executes during object creation, after setting all properties.
function tmaxInput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tmaxInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
