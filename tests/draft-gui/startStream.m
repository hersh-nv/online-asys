function err = startStream(hObject,h)
% input parameters


% timer 1
h.pullTimer=timer('Period',h.pullUpdatePeriod,...
    'TimerFcn',{@pullData,hObject},...
    'ExecutionMode','fixedSpacing'...
    ); % will need to run timing tests on TimerFcns to find appropriate
       % period for fixedRate
       % alternatively ExecutionMode could perhaps be changed to fixedSpacing;
       % this ensures no load issues because timer will wait for
       % callback fn to complete before restarting

% timer 2
h.populateTimer=timer('Period',h.populateUpdatePeriod,...
    'TimerFcn',{@fillArray,hObject},...
    'ExecutionMode','fixedSpacing'...
    );
guidata(hObject,h);

% start connection
err=0;
try
    cbmex('open');
    cbmex('mask',0,0); % deactivate all channels except for..
    for ch=h.minCh:h.maxCh
        cbmex('mask',ch,1); % channels 1-nCh
    end
    cbmex('trialconfig',1,'comment',20,'absolute','nocontinuous');
    start(h.pullTimer);
    start(h.populateTimer);
catch
    err=1;
end

end

% ===========================================================
% ========= callback functions begin here ===================
% ===========================================================

% buffer spike and comment data while trials are running
function pullData(timer,event,hObject)

h = guidata(hObject);
        
% use cbmex to pull data; active flag=1 on last pull clears buffer
spiketimesfull = cbmex('trialdata', 1);
[comments, commenttimes, ~, ~] = cbmex('trialcomment', 1);

%         % for debugging
%         if ~isempty(spiketimesfull{1,2})
%             disp([spiketimesfull{1,2}(1),length(spiketimesfull{1,2})])
%         end

spiketimes{h.maxCh,1}=[];
for ch=h.minCh:h.maxCh
    spiketimes{ch} = spiketimesfull{ch,2};
    % fill spike buffer
    h.spikebuffer{ch}=[h.spikebuffer{ch};spiketimes{ch}];
end

% fill comment buffers
h.cmtbuffer=[h.cmtbuffer;comments];
h.cmttimesbuffer=[h.cmttimesbuffer;commenttimes];

guidata(hObject,h);
    
end

% poll buffers until at least one full trial has completed, then store
% trial-onset-relative times in a persistent array
% TODO: add a clear array option to start analysis again from scratch,
% can eventually become a GUI button
% TODO: this doesn't need to be on a timer. move the cmtbuffer checks into
% pullData and trigger fillArray if size(cmtbuffer,1)>=2
function fillArray(timer,event,hObject)

    h = guidata(hObject);

    % some comments are not related to trial start, and contain 'F='
    % discard these from buffer
    if ~isempty(h.cmtbuffer)
        for cmt=1:size(h.cmtbuffer,1);
            match(cmt)=isempty(regexp(h.cmtbuffer{cmt},'F='));
        end
        h.cmtbuffer=h.cmtbuffer(find(match));
        h.cmttimesbuffer=h.cmttimesbuffer(find(match));
    end
    
%     keyboard;
    
    % check whether there's at least two comments in buffer, i.e. a
    % full trial has occurred
    while size(h.cmtbuffer,1)>=2

        % if first trial of block, get total stim variants to
        % preallocate trialdata cell array size
        if isempty(h.trialdata)
            matches=(regexp(h.cmtbuffer{1},'(of)([0-9]+)','tokens'));
            h.totalID=str2double(matches{:}{2});
            h.trialdata{h.maxCh,h.totalID,1}=[];
            h.IDreps = zeros(h.totalID,1);
        end
        

        % handle: find trial type from ID#,
        % move trial-relative spike times to trialdata array
        matches=(regexp(h.cmtbuffer{1},'(ID=)([0-9]+)','tokens'));
        idtype=str2double(matches{:}{2});
        
        count=h.IDreps(idtype)+1;
        for ch=h.minCh:h.maxCh
            spikeidx=find(h.spikebuffer{ch}>=h.cmttimesbuffer(1) & h.spikebuffer{ch}<h.cmttimesbuffer(2));
            if ~isempty(spikeidx)
                % find empty trial slot
%                 count=1;
%                 while ~isempty(h.trialdata{ch,idtype,count})
%                     count=count+1;
%                 end
                
                
                h.trialdata{ch,idtype,count}=h.spikebuffer{ch}(spikeidx)-h.cmttimesbuffer(1);
                h.trialdata{ch,idtype,count+1}=[];

                % clear moved spikes from buffer
                h.spikebuffer{ch}=h.spikebuffer{ch}(spikeidx(end)+1:end);
            end
        end
        h.IDreps(idtype)=h.IDreps(idtype)+1;
        fprintf('Stim ID %2d: spikes read.\n',idtype);

        % clear earliest comment from buffer
        h.cmtbuffer=h.cmtbuffer(2:end,1);
        h.cmttimesbuffer=h.cmttimesbuffer(2:end,1);
    end
    % Update handles structure
    guidata(hObject,h);
end