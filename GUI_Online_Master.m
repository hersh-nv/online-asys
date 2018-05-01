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

% Last Modified by GUIDE v2.5 01-May-2018 16:04:53

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
handles = initializeInputParams(handles);

% set master figure size
res = get(groot, 'Screensize');
START_BAR_HEIGHT = 40; % there must be a smarter way to get this but i don't know how
TITLE_BAR_HEIGHT = 31; % likewise
handles.pos = floor(res.*[1,1,0.15,1]) + ... % left 15% of screen
    [0,START_BAR_HEIGHT,0,-START_BAR_HEIGHT-TITLE_BAR_HEIGHT]; % leaving room for Win10 elements

handles.pos_pa = floor(res.*[1,1,0.85,1]) + ... % right 85% of screen
    [handles.pos(3),START_BAR_HEIGHT,0,-START_BAR_HEIGHT-TITLE_BAR_HEIGHT]; % leaving room for Win10 elements


wwidth = handles.pos(3);
wheight= handles.pos(4);

% set element sizes relative to master figure position/size
set(handles.streamButton,'String','Stream from NSP');
set(handles.streamButton,'Position',[20 wheight-60 wwidth-40 40]);

set(handles.streamStatusText1,'String','');
set(handles.streamStatusText1,'Position',[20,wheight-90,wwidth-40,20]);

set(handles.streamStatusText2,'String','Total trials:');
set(handles.streamStatusText2,'Position',[20,wheight-300,wwidth-40,200]);

set(handles.streamStimButton,'String','Stream from Stim PC');
set(handles.streamStimButton,'Position',[20,wheight-370,wwidth-40,40]);

set(handles.plotButton,'String','Start plot');
set(handles.plotButton,'Position',[20,20,wwidth-40,40]);
set(handles.plotButton','Enable','On');

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = GUI_Online_Master_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'Visible','on');
set(hObject,'Units','Pixels','Position',handles.pos);

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in streamButton.
function streamButton_Callback(hObject, eventdata, handles)
ispressed = get(hObject,'Value');
if (ispressed)
    err = startCBMEX(hObject);
    if (err)
        set(handles.streamStatusText1,'String','Failed to open CBMEX');
        set(handles.streamStatusText1,'ForegroundColor',[1 0.2 0.2]);
        set(hObject,'Value',0);
    else
        set(handles.streamStatusText1,'String','CBMEX opened');
        set(handles.streamStatusText1,'ForegroundColor',[0.2 0.8 0.2]);
        set(handles.streamButton,'String','Close stream');
        set(handles.plotButton','Enable','On');
    end
else if (~ispressed)
    stopCBMEX();
end
end

% --- Executes on button press in streamStimButton.
function streamStimButton_Callback(hObject, eventdata, handles)

% --- Executes on button press in plotButton.
function plotButton_Callback(hObject, eventdata, handles)
% matlab GUI .m files have a convoluted way of handling input variables, but in
% the end the inputs do get passed along (in the form of varargin) to the
% GUI's openingFcn. there, i push this input (pointer to this figure's handles) into
% that figure's handles, and the LHS of the below line does vice versa.
% in other words, in this GUI, handles.handles_plotAll points to other GUI,
% and in other GUI, handles.handles_master points here.
handles.handles_plotAll = GUI_Online_PlotAll('handles_master',handles);
guidata(hObject,handles);
