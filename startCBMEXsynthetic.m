function err = startCBMEXsynthetic(h)
%  startCBMEXsynthetic(handles) uses a MATLAB timer object to pull
%  synthetic neural and stim data periodically. When full trials have
%  completed, spike times are trial-aligned and moved to a persistent array
%  called 'spikedata' of size nChannels * nStimulusConditions *
%  nStimulusRepetitions.

%  HN May 2018

% update status text
set(h.streamStatusText1,'String','Opening...');
set(h.streamStatusText1,'ForegroundColor',[0,0,0]);

% create timer
h.pullTimer = timer('Period',1, ...
    'TimerFcn',{@pullNeuralData,h.figure1}, ...
    'ExecutionMode','fixedRate', ...
    'BusyMode', 'queue', ...
    'StartDelay',0.5 ...
    );

% CBMEX synthetic only accepts channels 1-32
h.minCh = 1;
h.maxCh = 32;

% initialise CBMEX connection
err=0;
try
    start(h.pullTimer);
catch
    err=1;
end

% update handles struct
guidata(h.figure1,h);

end
