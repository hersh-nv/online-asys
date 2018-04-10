function varargout = openStream(varargin)
% OPENSTREAM MATLAB code for openStream.fig
%      OPENSTREAM, by itself, creates a new OPENSTREAM or raises the existing
%      singleton*.
%
%      H = OPENSTREAM returns the handle to a new OPENSTREAM or the handle to
%      the existing singleton*.
%
%      OPENSTREAM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OPENSTREAM.M with the given input arguments.
%
%      OPENSTREAM('Property','Value',...) creates a new OPENSTREAM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before openStream_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to openStream_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help openStream

% Last Modified by GUIDE v2.5 04-Apr-2018 14:47:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @openStream_OpeningFcn, ...
                   'gui_OutputFcn',  @openStream_OutputFcn, ...
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


% --- Executes just before openStream is made visible.
function openStream_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to openStream (see VARARGIN)

% Choose default command line output for openStream
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes openStream wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = openStream_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in startCBMEXbutton.
function startCBMEXbutton_Callback(hObject, eventdata, handles)
% hObject    handle to startCBMEXbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bool = get(hObject,'Value');
updateStatus(bool);
% Hint: get(hObject,'Value') returns toggle state of startCBMEXbutton

% --- Executes on button press in streamStatus.
function streamStatus_Callback(hObject, eventdata, handles)
% hObject    handle to streamStatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of streamStatus

function updateStatus_Callback(hObject, eventdata, handles)
% keyboard;
bool = get(handles.startCBMEXbutton,'Value');
if (bool) set(handles.streamStatusText,'String','CBMEX on');
else      set(handles.streamStatusText,'String','CBMEX off');
end