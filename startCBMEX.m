function err = startCBMEX(hObject)
%  Opens a connection to a PC running Blackrock Central software and uses a
%  MATLAB timer object to pull neural and stim data recurrently at a set
%  period. When full trials have completed, spike times are trial-aligned
%  and moved to a persistent array called 'spikedata' of size nChannels *
%  nStimulusTypes * nStimulusRepetitions.

%  HN May 2018

h = guidata(hObject); % get figure handles

% update status text
set(h.streamStatusText1,'String','Opening...');
set(h.streamStatusText1,'ForegroundColor',[0,0,0]);
guidata(hObject,h);

% create timer
h.pullTimer=timer('Period',h.pullUpdatePeriod,...
    'TimerFcn',{@pullCBMEX,hObject},...
    'ExecutionMode','fixedSpacing'...
    );

% initialise CBMEX connection
err=0;
try
    cbmex('open');
    cbmex('mask',0,0); % deactivate all channels except for..
    for ch=h.minCh:h.maxCh
        cbmex('mask',ch,1); % channels 1-nCh
    end
    cbmex('trialconfig',1,'comment',20,'absolute','nocontinuous');
    %start(h.pullTimer);
catch
    err=1;  % stream failed: is Central running? is network connection to Central working?
end

guidata(hObject,h);
end


function pullData(timer, event, hObject)
end