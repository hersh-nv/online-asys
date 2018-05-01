% august 2017 hersh nevgi

% uses a timer to poll data acquisition machine for spikes periodically
% pulls spike and stim data into a buffer before sorting into a cell array
% 'trialdata' of size nCh*nID*nRep:
%   - nCh : number of channels being recorded
%   - nStim : number of stimulus variants, e.g. orientations
%   - nRep: maximum number of repetitions of each stimulus variation
% trialdata contains spiketimes across each channel relative to trial start times.
% any existing analysis functions can be inserted into refreshImages() to
% run on the streamed and buffered data

function [spikebuffer,cmtbuffer,cmttimesbuffer,trialdata]=realTimeAsys()

    % input parameters
    nCh=32;
    nRep=20;  % maximum number of stimuli repetitions for each type
    
    % initialise empty buffers and other variables
    spikebuffer{32,1}=[];
    cmtbuffer = [];
    cmttimesbuffer = [];
    trialdata={};
    h=[];
    
    % define update periods in sec
    pullUpdatePeriod = 0.25;     % how often to pull spike data     
    populateUpdatePeriod = 1;   % how often to populate trial-sorted spike array with pull data
    imageUpdatePeriod = 5;      % how often to update the figures

    % timer 1
    pullTimer=timer('Period',pullUpdatePeriod,...
        'TimerFcn',@pullData,...
        'ExecutionMode','fixedSpacing'...
        ); % will need to run timing tests on TimerFcns to find appropriate
           % period for fixedRate
           % alternatively ExecutionMode could perhaps be changed to fixedSpacing;
           % this ensures no load issues because timer will wait for
           % callback fn to complete before restarting
    
    % timer 2
    populateTimer=timer('Period',populateUpdatePeriod,...
        'TimerFcn',@fillArray,...
        'ExecutionMode','fixedSpacing'...
        );
           
    % timer 3
    imageTimer=timer('Period',imageUpdatePeriod,...
        'TimerFcn',{@refreshFigures},...
        'ExecutionMode','fixedSpacing'...
        );
           
           
    % start connection
    cbmex('open');
    cbmex('mask',0,0); % deactivate all channels except for..
    for ch=1:nCh
        cbmex('mask',ch,1); % channels 1-nCh
    end
    cbmex('trialconfig',1,'comment',20,'absolute','nocontinuous');
    start(pullTimer);
    start(populateTimer);
%     start(imageTimer); uncomment when completed

    % continue until figure/s is closed
    uiwait(gcf);

    % delete all timer/s, close connection
    stop(timerfind); delete(timerfind);
    cbmex('trialconfig',0); cbmex('close');
    disp('Data stream ended');
    
    
    % ===========================================================
    % ========= callback functions begin here ===================
    % ===========================================================
    
    % buffer spike and comment data while trials are running
    function pullData(timer,event)
        
        % use cbmex to pull data; active flag=1 on last pull clears buffer
        spiketimesfull = cbmex('trialdata', 1);
        [comments, commenttimes, ~, ~] = cbmex('trialcomment', 1);
        
%         % for debugging
%         if ~isempty(spiketimesfull{1,2})
%             disp([spiketimesfull{1,2}(1),length(spiketimesfull{1,2})])
%         end
        
        spiketimes{nCh,1}=[];
        for ch=1:nCh
            spiketimes{ch} = spiketimesfull{ch,2};
            % fill spike buffer
            spikebuffer{ch}=[spikebuffer{ch};spiketimes{ch}];
        end
                
        % fill comment buffers
        cmtbuffer=[cmtbuffer;comments];
        cmttimesbuffer=[cmttimesbuffer;commenttimes];
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % poll buffers until at least one full trial has completed, then store
    % trial-onset-relative times in a persistent array
    % TODO: add a clear array option to start analysis again from scratch,
    % can eventually become a GUI button
    function fillArray(timer,event)
                
        % some comments are not related to trial start, and contain 'F='
        % discard these from buffer
        if ~isempty(cmtbuffer)
            for cmt=1:size(cmtbuffer,1);
                match(cmt)=isempty(regexp(cmtbuffer{cmt},'F='));
            end
            cmtbuffer=cmtbuffer(find(match));
            cmttimesbuffer=cmttimesbuffer(find(match));
        end
        
        % check whether there's at least two comments in buffer, i.e. a
        % full trial has occurred
        while size(cmtbuffer,1)>=2
            
            % if first trial of block, get total stim variants to
            % preallocate trialdata cell array size
            if isempty(trialdata)
                matches=(regexp(cmtbuffer{1},'(of)([0-9]+)','tokens'));
                nID=str2double(matches{:}{2});
                trialdata{nCh,nID,nRep}=[];
            end
            
            % handle: find trial type from ID#,
            % move trial-relative spike times to trialdata array
            matches=(regexp(cmtbuffer{1},'(ID=)([0-9]+)','tokens'));
            idtype=str2double(matches{:}{2});
            
            for ch=1:nCh
                spikeidx=find(spikebuffer{ch}>=cmttimesbuffer(1) & spikebuffer{ch}<cmttimesbuffer(2));
                if ~isempty(spikeidx)
                    count=1;
                    while ~isempty(trialdata{ch,idtype,count})
                        count=count+1;
                    end
                    
                    trialdata{ch,idtype,count}=spikebuffer{ch}(spikeidx)-cmttimesbuffer(1);
                    % fprintf('Copied to trialdata.\n');

                    % clear moved spikes from buffer
                    spikebuffer{ch}=spikebuffer{ch}(spikeidx(end)+1:end);
                end
            end
            fprintf('Stim ID %2d: spikes read.\n',idtype);
            
            % clear earliest comment from buffer
            cmtbuffer=cmtbuffer(2:end,1);
            cmttimesbuffer=cmttimesbuffer(2:end,1);
            
        end
    end

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % TODO
    % refresh figures from analysis tools on the trial-relative spike data
    function refreshFigures(timer,event)
        
        if isempty(h)
            % create figure
            h = plot(1:12,zeros(1,12));
            xlim([1 12]);
        end
        
        % update figure
        meanresp=zeros(1,12);
        for d=1:12
            for dx=1:length(trialdata(1,d,:));
                meanresp(d) = meanresp(d)+length(trialdata{1,d,dx});
            end
            meanresp(d) = meanresp(d)/dx;
        end
        
    end
    
end