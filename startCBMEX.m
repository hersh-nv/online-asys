function err = startCBMEX(h)
%  startCBMEX(handles) opens a connection to a PC running Blackrock Central
%  software and uses a MATLAB timer object to pull neural and stim data
%  recurrently at a set period. When full trials have completed, spike
%  times are trial-aligned and moved to a persistent array called
%  'spikedata' of size nChannels * nStimulusTypes * nStimulusRepetitions.

%  HN May 2018

% update status text
set(h.streamStatusText1,'String','Opening...');
set(h.streamStatusText1,'ForegroundColor',[0,0,0]);

% create timer
h.pullTimer = timer('Period',h.pullUpdatePeriod,...
    'TimerFcn',{@pullCBMEX,h},...
    'ExecutionMode','fixedSpacing'...
    );

% initialise CBMEX connection
err=0;
try
    cbmex('open');
    cbmex('mask',0,0); % deactivate all channels except for..
    for ch=h.minCh:h.maxCh
        cbmex('mask',ch,1); % channels minCh-maxCh
    end
    cbmex('trialconfig',1,'comment',20,'absolute','nocontinuous');
    start(h.pullTimer);
catch
    err=1;
end

% update handles struct
guidata(h.figure1,h);

end

%% Timer callback
function pullCBMEX(~, ~, h)
try
% Callback function for pullTimer. On every call, it checks the CBMEX
% network buffer and empties the neural and comment data into an
% accumulating local buffer. After every complete trial, the data is moved
% into a spike array (handles.spikedata) which is used elsewhere for
% online analysis.
%
% See also STARTCBMEX

% use cbmex to pull data; second arg=1 clears buffer
[cbmexSpikeBuffer,~,~] = cbmex('trialdata', 1);
[cbmexCmtBuffer, cbmexCmtTimesBuffer, ~, ~] = cbmex('trialcomment', 1);

% move cbmex neural data into local buffer
%spiketimes{h.maxCh,1}=[];
for ch=h.minCh:h.maxCh
    % spiketimes{ch} = cbmexSpikeBuffer{ch,2};
    % fill spike buffer
    h.spikebuffer{ch}=[h.spikebuffer{ch};cbmexSpikeBuffer{ch,2}];%spiketimes{ch}];
end

% some comments are not related to trial start, and contain 'F='.
% discard these from buffer
if ~isempty(cbmexCmtBuffer)
    match=zeros(1,size(cbmexCmtBuffer,1));
    for cmt=1:size(cbmexCmtBuffer,1)
        match(cmt)=isempty(regexp(cbmexCmtBuffer{cmt},'F='));
    end
    cbmexCmtBuffer      = cbmexCmtBuffer(find(match));
    cbmexCmtTimesBuffer = cbmexCmtTimesBuffer(find(match));
end

% move cbmex comment data into local buffer
h.cmtbuffer=[h.cmtbuffer;cbmexCmtBuffer];
h.cmttimesbuffer=[h.cmttimesbuffer;cbmexCmtTimesBuffer];

% if at least two comments, at least one full trial has passed,
% and spike data can be trial-aligned and moved into full array
while size(h.cmtbuffer,1)>=2

    % if first trial of block, get total stim variants from comments
    % to preallocate spikedata cell array size
    if isempty(h.spikedata)
        matches=(regexp(h.cmtbuffer{1},'(of)([0-9]+)','tokens'));
        h.stimTypesTotal = str2double(matches{:}{2});
        h.spikedata{h.maxCh,h.stimTypesTotal,1} = [];
        h.stimTypeReps = zeros(h.stimTypesTotal,1);
    end
    
    % handle: find stim type from ID#,
    matches=(regexp(h.cmtbuffer{1},'(ID=)([0-9]+)','tokens'));
    stim=str2double(matches{:}{2});

    stimCount=h.stimTypeReps(stim)+1;
    % on each channel,
    for ch=h.minCh:h.maxCh
        % find spikes inside trial start and end
        spikeidx=find(h.spikebuffer{ch}>=h.cmttimesbuffer(1) & h.spikebuffer{ch}<h.cmttimesbuffer(2));
        if ~isempty(spikeidx)
            % subtract trial start time, move to spikedata and clear from
            % spikebuffer
            h.spikedata{ch,stim,stimCount}=h.spikebuffer{ch}(spikeidx)-h.cmttimesbuffer(1);
            h.spikebuffer{ch}=h.spikebuffer{ch}(spikeidx(end)+1:end);
        end
    end
    h.stimTypeReps(stim)=h.stimTypeReps(stim)+1;
    fprintf('Stim ID %2d: spikes read.\n',stim);

    % clear this trial (comment) from buffer
    h.cmtbuffer         = h.cmtbuffer(2:end,1);
    h.cmttimesbuffer    = h.cmttimesbuffer(2:end,1);
end

% Update handles structure
guidata(h.figure1,h);

catch ME
    getReport(ME);
    keyboard;
end
end