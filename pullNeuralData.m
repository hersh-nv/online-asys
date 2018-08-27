function pullNeuralData(~, ~, f)
% Callback function for pullTimer. On every call, it checks the CBMEX
% network buffer and empties the neural and comment data into an
% accumulating local buffer. After every complete trial, the data is moved
% into a spike array (handles.spikedata) which is used elsewhere for
% online analysis.
%
% See also STARTCBMEX

try
% get handles
h = guidata(f);

swtoc=[];
sw = tic;

if strcmp(h.streamSel,'CBMEX')
    [spikeBufferTmp,~,~] = cbmex('trialdata', 1);
    [cmtBufferTmp, cmtTimesBufferTmp, ~, ~] = cbmex('trialcomment', 1);
elseif strcmp(h.streamSel,'CBMEX_synthetic')
    [spikeBufferTmp, cmtBufferTmp,cmtTimesBufferTmp] = cbmex_Synthetic(5);
end

% convert from sample counts to seconds
cmtTimesBufferTmp = cmtTimesBufferTmp./h.sampling_freq;

% move cbmex neural data into local buffer
for ch=h.chStreamRange
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
    cmtBufferTmp      = cmtBufferTmp(match);
    cmtTimesBufferTmp = cmtTimesBufferTmp(match);
end

% move cbmex comment data into local buffer
h.cmtbuffer=[h.cmtbuffer;cmtBufferTmp];
h.cmttimesbuffer=[h.cmttimesbuffer;cmtTimesBufferTmp];

% if at least two comments, at least one full trial has passed,
% and spike data can be trial-aligned and moved into full array
while size(h.cmtbuffer,1)>=2

    % if first trial of block, parse comments to find total num stim
    % conditions, preallocate spikedata cell array size
    if isempty(h.spikedata)
        h.totaltrials = 0;
        
        % find all stim conditions
        matches=regexp(h.cmtbuffer{1},';n([a-z_A-Z]+)=([0-9]+)','tokens');
        for n = 1:size(matches,2)
            h.stimLabels{n} = matches{n}{1};
            h.nStim(n) = str2double(matches{n}{2});
        end
        
        h.stimIdxs = fullfact(h.nStim);
        h.spikedata{h.maxCh,size(h.stimIdxs,1),1} = [];
        h.spikerate = nan(size(h.spikedata));
        h.stimElapsed = zeros(size(h.stimIdxs,1),1);
        h.stimVals = nan(n, max(h.nStim));
        
        % update param select menu(s)
        h.param1Select.String = h.stimLabels';
        h.param1Select.Enable = 'On';
        h.param2Select.String = ['All';h.stimLabels(2:end)'];
        h.param2Select.Enable = 'On';
        h.param2ValSelect.String = {'All'};
        
        h.plotButton.Enable = 'On';
        
        % update stimulus status text
        h.stimText = sprintf('%d %s',h.nStim(1),h.stimLabels{1});
        for ss = 2:length(h.nStim)
            h.stimText = sprintf([h.stimText,'  *  %d %s'],h.nStim(ss),h.stimLabels{ss});
        end
    end
    
    % find current stim idx
    matches=regexp(h.cmtbuffer{1},';ind[a-z_A-Z]+=([0-9]+)','tokens');
    mask = true(size(h.stimIdxs,1),1);
    for n = 1:size(matches,2)
        h.thisIdxs(n) = str2double(matches{n}{1});
        mask = mask & h.stimIdxs(:,n)==h.thisIdxs(n);
    end    
    
    % find current stim val
    matches=regexp(h.cmtbuffer{1},';this[a-z_A-Z]+=([-0-9]+)','tokens');
    for n = 1:size(matches,2)
        h.stimVals(n,h.thisIdxs(n)) = str2double(matches{n}{1});
    end
    
    thisStim = find(mask,1);
    h.thisStim = thisStim; % condition of just-elapsed trial
    
    stimCount=h.stimElapsed(thisStim)+1;
    % on each channel ...
    for ch=h.chStreamRange
        % ... find spikes inside trial start and end
        spikeidx=(h.spikebuffer{ch}>=h.cmttimesbuffer(1) & h.spikebuffer{ch}<h.cmttimesbuffer(2));
        if ~isempty(spikeidx)
            % subtract trial start time, move to spikedata, clear from
            % buffer
            h.spikedata{ch,thisStim,stimCount}=h.spikebuffer{ch}(spikeidx)-h.cmttimesbuffer(1);
            h.spikebuffer{ch}=h.spikebuffer{ch}(spikeidx(end)+1:end);
        end
    end
    h.stimElapsed(thisStim)=h.stimElapsed(thisStim)+1;
    h.totaltrials = h.totaltrials + 1;
    
    % notify user of new trial
    statusText = sprintf(['\n'...
        h.stimText,'\n', ...
        'Total trials = %d\n', ...
        ], h.totaltrials);
    h.streamStatusText2.String = statusText;

    % clear this trial (comment) from buffer
    h.cmtbuffer         = h.cmtbuffer(2:end,1);
    h.cmttimesbuffer    = h.cmttimesbuffer(2:end,1);
    
%     % %%%%%%%%%%% for debugging skipped elapsed values %%%%%%%%%%%%%%
%     [sdy, sdx, sdz] = size(h.spikedata);
%     elapsed = squeeze(1-cellfun(@isempty,h.spikedata(1,:,:)));
%     a = find(elapsed(:,
%     % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % update figures
    if ishandle(h.figure_overview)
       overviewWindow = overviewWindowSwitchyard();
       overviewWindow.update(h.figure_overview);
    end
    for ifocus = find(h.figure_focusMat)
        focusWindow = focusWindowSwitchyard();
        focusWindow.update(h.figure_focus{ifocus});
    end
    swtoc(end+1)=toc(sw)*1e3;
    
    % print to command window
    if (h.verbose)
        for n = 1:size(matches,2)
            fprintf("%s %2d | ",h.stimLabels{n},h.thisIdxs(n));
        end
        fprintf(' t =');
        for iprint=1:length(swtoc)
            fprintf(' %3.1f',swtoc(iprint));
        end
        fprintf('.\n');
    end
end

% Update handles structure
guidata(h.figure1,h);

% Hooray for figuring out easy debugging of callbacks
catch err
    getReport(err)
    keyboard;
end
end