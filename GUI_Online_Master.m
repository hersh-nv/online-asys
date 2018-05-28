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

% Last Modified by GUIDE v2.5 28-May-2018 22:33:41

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
    [0,0,0,-START_BAR_HEIGHT-TITLE_BAR_HEIGHT]; % leaving room for Win10 elements

wwidth = handles.pos(3);
wheight= handles.pos(4);

% set element sizes relative to master figure position/size
handles.streamSelectMenu.Position = [20, wheight-65, 80, 40];

handles.streamButton.String = 'Start NSP stream';
handles.streamButton.Position = [120 wheight-50 wwidth-140 30];

handles.streamStatusText1.String = '';
handles.streamStatusText1.Position = [20,wheight-90,wwidth-40,20];

handles.streamStatusText2.String = '';
handles.streamStatusText2.Position = [20,wheight-300,wwidth-40,200];

handles.plotSettingsPanel.Position = [10,wheight-500,wwidth-20,180];
handles.channelInputLabel.Position = [10,140,120,20];
handles.channelInput.Position = [140,140,wwidth-170,20];

handles.streamStimButton.String = 'Stream from Stim PC';
handles.streamStimButton.Position = [20,80,wwidth-40,40];

handles.plotButton.String = 'Start plot';
handles.plotButton.Position = [20,20,wwidth-40,40];
handles.plotButton.Enable = 'Off';

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

% If button is being used to start stream
if strcmp(hObject.String,'Start NSP stream')
    % Check which stream type is selected
    streamOpts = handles.streamSelectMenu.String;
    handles.streamSel = streamOpts{handles.streamSelectMenu.Value};
    
    if strcmp(handles.streamSel,'CBMEX')
        err = startCBMEX(handles);
        if (err)
            set(handles.streamStatusText1,'String','Failed to open CBMEX');
            set(handles.streamStatusText1,'ForegroundColor',[1 0.2 0.2]);

            errstatus = sprintf(['\n'...
                'Is Central running on acquisition PC?\n' ...
                'Is acquisition PC''s IP address 192.168.137.1?\n' ...
                'Can this PC successfully ping that IP?']);
            set(handles.streamStatusText2,'String',errstatus);
            set(hObject,'Value',0);
        else
            handles.streamStatusText1.String = 'CBMEX opened';
            handles.streamStatusText1 = ForegroundColor',[0.2 0.8 0.2];
            handles.streamStatusText2.String = '';
            handles.streamButton.String = 'Close stream';
            handles.plotButton.Enable = 'On';
        end
    elseif strcmp(handles.streamSel,'CBMEX_synthetic')
        err = startCBMEXsynthetic(handles);
        if (err)
            % this is not anticipated
        else
            handles.streamStatusText1.String = 'Synthetic CBMEX started';
            handles.streamStatusText1.ForegroundColor = [0.2 0.8 0.2];
            handles.streamStatusText2.String = '';
            handles.streamButton.String = 'Close stream';
            handles.plotButton.Enable = 'On';
        end
    end
% Else, the button stops the stream
else
    endStream();
    handles.streamButton.String = 'Start NSP stream';
    handles.streamStatusText1.String = 'Stream closed';
    handles.streamStatusText1.ForegroundColor = [0 0 0];
end


% --- Executes on button press in streamStimButton.
function streamStimButton_Callback(hObject, eventdata, handles)


% --- Executes on button press in plotButton.
function plotButton_Callback(hObject, eventdata, handles)
% Create plotAll figure. Pass the current figure handles so that plotAll
% can add it to its 'handles' structure. plotAll outputs its own figure
% handles so the next line can do vice versa. Both GUI handles contain a
% reference to other figure.
handles.figure_plotAll = GUI_Online_PlotAll(handles.figure1);
guidata(hObject,handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% when closing fig, this closereqfcn makes sure CBMEX is closed and timers
% deleted in case the user hasn't pressed the Stop Stream button
endStream();
delete(hObject);


% --- Executes on selection change in streamSelectMenu.
function streamSelectMenu_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function streamSelectMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to streamSelectMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function channelInput_Callback(hObject, eventdata, handles)
chText = get(hObject,'String');
if ~isnan(str2double(chText))   % single channel number
    ch = str2double(chText);
    if ch==0
        h.minCh = 1;
        h.maxCh = 32;
        fprintf('Channel range set: %d:%d\n',1,32);
    else
        h.minCh = str2double(chText);
        h.maxCh = str2double(chText);
        fprintf('Channel range set: %d:%d\n',ch,ch);
    end
else
    matches = regexp(chText,'([0-9]+):([0-9]+)','tokens');
    try
        minCh = str2double(matches{1}{1});
        maxCh = str2double(matches{1}{2});
        if (~isnan(minCh) && minCh>0 && minCh<maxCh)
            handles.minCh = minCh; fprintf('Channel range set: %d',minCh);
        end
        if (~isnan(maxCh) && maxCh>minCh) % no error handling if maxCh is later out of bounds
            handles.maxCh = maxCh; fprintf(':%d\n',maxCh);
        end
    catch
    end
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function channelInput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in param1Select.
function param1Select_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function param1Select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to param1Select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
