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
    'TimerFcn',{@pullCBMEXsynthetic,h.figure1}, ...
    'ExecutionMode','fixedSpacing', ...
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

%% Timer callback
function pullCBMEXsynthetic(~, ~, f)
try
% Callback function for pullTimer. On every call, it checks the CBMEX
% network buffer and empties the neural and comment data into an
% accumulating local buffer. After every complete trial, the data is moved
% into a spike array (handles.spikedata) which is used elsewhere for
% online analysis.
%
% See also STARTCBMEX

% get handles
h = guidata(f);

[spikeBufferTmp, cmtBufferTmp,cmtTimesBufferTmp] = cbmex_Synthetic();

% convert from sample counts to seconds
cmtTimesBufferTmp = cmtTimesBufferTmp./h.sampling_freq;

% move cbmex neural data into local buffer
for ch=h.minCh:h.maxCh
    % convert from sample counts to seconds
    spikeBufferTmp{ch,2} = spikeBufferTmp{ch,2}./h.sampling_freq;
    % fill spike buffer
    h.spikebuffer{ch}=[h.spikebuffer{ch},spikeBufferTmp{ch,2}];
end

% some comments are not related to trial start, and contain 'F='.
% discard these from buffer
if ~isempty(cmtBufferTmp)
    match=zeros(1,size(cmtBufferTmp,1));
    for cmt=1:size(cmtBufferTmp,1)
        match(cmt)=isempty(regexp(cmtBufferTmp{cmt},'F='));
    end
    cmtBufferTmp      = cmtBufferTmp(find(match));
    cmtTimesBufferTmp = cmtTimesBufferTmp(find(match));
end

% move cbmex comment data into local buffer
h.cmtbuffer=[h.cmtbuffer;cmtBufferTmp];
h.cmttimesbuffer=[h.cmttimesbuffer;cmtTimesBufferTmp];

% if at least two comments, at least one full trial has passed,
% and spike data can be trial-aligned and moved into full array
while size(h.cmtbuffer,1)>=2

    % if first trial of block, get total stim variants from comments
    % to preallocate spikedata cell array size
    if isempty(h.spikedata)
        h.totaltrials = 0;
        matches=(regexp(h.cmtbuffer{1},'(nDir=)([0-9]+)','tokens'));
        h.stimTypesTotal = str2double(matches{:}{2});
        h.spikedata{h.maxCh,h.stimTypesTotal,1} = [];
        h.stimTypeReps = zeros(h.stimTypesTotal,1);
    end
    
    % handle: find stim type from ID#,
    matches=(regexp(h.cmtbuffer{1},'(indDir=)([0-9]+)','tokens'));
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
    
    % notify user of new trial
    h.totaltrials = h.totaltrials + 1;
    statusText = sprintf(['\n'...
                'Total trials = %d\n', ...
                ], h.totaltrials);
    h.streamStatusText2.String = statusText;
    fprintf('Stim ID %2d: spikes read.\n',stim);

    % clear this trial (comment) from buffer
    h.cmtbuffer         = h.cmtbuffer(2:end,1);
    h.cmttimesbuffer    = h.cmttimesbuffer(2:end,1);
end

% Update handles structure
guidata(h.figure1,h);

% Hooray for figuring out easy debugging of callbacks
catch err
    getReport(err)
    keyboard;
end
end