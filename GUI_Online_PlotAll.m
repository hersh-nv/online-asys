function varargout = GUI_Online_PlotAll(varargin)
% GUI_ONLINE_PLOTALL MATLAB code for GUI_Online_PlotAll.fig
%      GUI_ONLINE_PLOTALL, by itself, creates a new GUI_ONLINE_PLOTALL or raises the existing
%      singleton*.
%
%      H = GUI_ONLINE_PLOTALL returns the handle to a new GUI_ONLINE_PLOTALL or the handle to
%      the existing singleton*.
%
%      GUI_ONLINE_PLOTALL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_ONLINE_PLOTALL.M with the given input arguments.
%
%      GUI_ONLINE_PLOTALL('Property','Value',...) creates a new GUI_ONLINE_PLOTALL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_Online_PlotAll_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_Online_PlotAll_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_Online_PlotAll

% Last Modified by GUIDE v2.5 02-May-2018 14:30:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Online_PlotAll_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Online_PlotAll_OutputFcn, ...
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


% --- Executes just before GUI_Online_PlotAll is made visible.
function GUI_Online_PlotAll_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_Online_PlotAll (see VARARGIN)

% Choose default command line output for GUI_Online_PlotAll
handles.output = hObject;

% Retrieve master handles
handles.figure_master = varargin{1};

handles_master = guidata(handles.figure_master);

% set plotAll figure size
res = get(groot, 'Screensize');
START_BAR_HEIGHT = 40; % there must be a smarter way to get this but i don't know how
TITLE_BAR_HEIGHT = 31; % likewise

handles.pos = floor(res.*[1,1,0.85,1]) + ... % right 85% of screen
    [handles_master.pos(3),START_BAR_HEIGHT,0,-START_BAR_HEIGHT-TITLE_BAR_HEIGHT]; % leaving room for Win10 elements

wwidth = handles.pos(3);
wheight= handles.pos(4);

% create as many plot axes as required and assign positions dynamically
numplots = 32; % hardcoded just for now

yplots = floor(sqrt(numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(numplots/yplots);

%figure(gcf);      % draw into figure_plotAll
handles.axes{1,numplots}=[];
for iplot=1:numplots
    handles.axes{iplot}=subplot(yplots,xplots,iplot);
    handles.axes{iplot}.XTick=[];
    handles.axes{iplot}.YTick=[];
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_Online_PlotAll wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_Online_PlotAll_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'Units','Pixels','Position',handles.pos);
set(hObject,'Visible','On');

% Get default command line output from handles structure
varargout{1} = handles.output;
