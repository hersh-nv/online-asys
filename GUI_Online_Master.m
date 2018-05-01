function varargout = GUI_Online_Master(varargin)
% GUI_ONLINE_MASTER MATLAB code for GUI_Online_Master.fig
%      GUI_ONLINE_MASTER, by itself, creates a new GUI_ONLINE_MASTER or raises the existing
%      singleton*.
%
%      H = GUI_ONLINE_MASTER returns the handle to a new GUI_ONLINE_MASTER or the handle to
%      the existing singleton*.
%
%      GUI_ONLINE_MASTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_ONLINE_MASTER.M with the given input arguments.
%
%      GUI_ONLINE_MASTER('Property','Value',...) creates a new GUI_ONLINE_MASTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_Online_Master_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_Online_Master_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_Online_Master

% Last Modified by GUIDE v2.5 01-May-2018 00:04:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Online_Master_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Online_Master_OutputFcn, ...
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


% --- Executes just before GUI_Online_Master is made visible.
function GUI_Online_Master_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_Online_Master (see VARARGIN)

% Choose default command line output for GUI_Online_Master
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(hObject,'Units','Normalized','Position',[0, 0.2, 0.15, 0.8]);

set(handles.streamButton,'String','Start streaming from NSP');
set(handles.streamButton,'Units','Normalized');
set(handles.streamButton,'Position',[0.1,0.9,0.8,0.05]);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_Online_Master_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in streamButton.
function streamButton_Callback(hObject, eventdata, handles)
% hObject    handle to streamButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
