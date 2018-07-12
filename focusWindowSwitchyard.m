function f = focusWindowSwitchyard
% f = focusWindowSwitchyard() creates a switchyard object with
%       child functions to create or control a Focus window:
%
%       f.open(~,~,f_master,ch) creates a Focus window with PSTHs and
%           raster plots visualising the currently acquired spike data on a
%           given channel. f_master is the handle to the Master window of
%           the GUI. ch is the electrode channel number that the user
%           wishes to Focus on.
%       f.update(f) updates a Focus figure f.
%       f.close(f)  closes an Focus figure f and clears the associated
%           data.
%
%       HN - July 2018

f.open = @openFocusWindow;
f.update = @updateFocusWindow;
f.close = @closeFocusWindow;
end

% % ========== INITIALISATION FUNCTION ====================================
function openFocusWindow(~,~,f_master,ch)
% openFocusWindow(f_master) opens a Focus window with data from a single
% channel. There is no limit to the number of different Focus windows that
% can be open at a given time, but naturally a large number will put more
% strain on computer resources.
try
fprintf('Focusing on Channel %g!\n',ch);

% initialise handles, fetch master handles
h = struct;
h.figure_master = f_master;
h1 = guidata(f_master);

% create figure, save to handles
titlestr = sprintf('Channel %g',ch);

if h1.focusSettings.singletonCheck
    % if focus figure exists, occupy it and clear it
    existingFocus = find(h1.figure_focusMat);
    if isempty(existingFocus)
        f = figure('Name',titlestr,'NumberTitle','off');
    else
        for ff = existingFocus
            f = figure(h1.figure_focus{ff});
            f.Name = titlestr;
            clf;  
        end
    end
    h1.figure_focus={};
    h1.figure_focusMat=[];
% else just make a new figure
else
    f = figure('Name',titlestr,'NumberTitle','off');
end
h.figure1 = f;
h1.figure_focus{ch}=f;
h1.figure_focusMat(ch)=1;

% set figure position and other properties
f.CloseRequestFcn = @closeFocusWindow;

% save some data to handles
h.ch =      ch;
h.binSize = h1.focusSettings.psthBinSize/1000; % (s)
h.tMin =    h1.focusSettings.tMin; % (s)
h.tMax =    h1.focusSettings.tMax; % (s)
h.hMax =    20*h.binSize;
h.param1 =  h1.param1Select.Value;
h.param2 =  find(strcmp(h1.param2Select.String{h1.param2Select.Value},h1.stimLabels));
param2Val = str2double(h1.param2ValSelect.String{h1.param2ValSelect.Value});
if isnan(param2Val)
    h.param2ValIdx = 0;
else
    h.param2ValIdx = find(param2Val==h1.stimVals(h.param2,:));
end
h.rMax=20;

% start drawing subplots
h.numplots = h1.nStim(h.param1);
yplots = round(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);
% if h1.rasterCheck.Value
%     h.numplots = h.numplots * 2; % double, to fit in raster plots
%     yplots = yplots*2
% end


if (h1.param2Select.Value==1 || h1.param2ValSelect.Value>1)
    h.spiketrain{h.numplots} = [];
    h.spiketrain2{h.numplots}=[];
    h.tc{h.numplots}=[]; % trial count
    h.tcnum=ones(1,h.numplots);
else
    h.numCurves = h1.nStim(h.param2);
    h.spiketrain{h.numplots,h.numCurves} = [];
    h.spiketrain2{h.numplots,h.numCurves}=[];
    h.tc{h.numplots,h.numCurves}=[]; % trial count
    h.tcnum=ones(1,h.numplots);
    % new colour order
    newCO=[linspace(0,1,h.numCurves)', ...
        zeros(h.numCurves,1), ...
        linspace(1,0,h.numCurves)'];
end

n = 1:h.numplots;
% subplotidxs = floor((n-1)/xplots)*xplots+n; % only when using rasters
wwidthp=0.95; % proportional window width and
wheightp=0.9; % height for the subplots to be drawn inside
for n = 1:h.numplots
    if h1.rasterCheck.Value
        % subplotidx = floor((n-1)/xplots)*xplots+n; % take every second row
        % subplot(yplots*2,xplots,subplotidxs(n));
        pos(1) = mod(n-1,xplots)*wwidthp/xplots + (1-wwidthp);
        pos(2) = (1+wwidthp)/2-wheightp/yplots*ceil(n/xplots) + wheightp/yplots*0.2;
        pos(3) = wwidthp/xplots*0.75;
        pos(4) = wheightp/yplots*0.6;
        subplot('Position',pos);
    else
        %subplot(yplots,xplots,n);
        pos(1) = mod(n-1,xplots)*wwidthp/xplots + (1-wwidthp);
        pos(2) = (1+wwidthp)/2-wheightp/yplots*ceil(n/xplots);
        pos(3) = wwidthp/xplots*0.75;
        pos(4) = wheightp/yplots*0.9;
        subplot('Position',pos);
    end
    
    % %%%% single curve
    if (h1.param2Select.Value==1 || h1.param2ValSelect.Value>1)
        mask = h1.stimIdxs(:,h.param1) == n;
        if h1.param2ValSelect>1
            mask = mask & h1.stimIdxs(:,h.param2) == h.param2ValIdx;
        end
        h.spiketrain{n} = sort([h1.spikedata{ch,mask,:}]);

        h.hists{n} = histogram(h.spiketrain{n},h.tMin:h.binSize:h.tMax, ...
            'DisplayStyle','stairs'); % TODO: custom bin size and time window
        elapsedSum = sum(h1.stimElapsed(mask));
        if elapsedSum>0 
            % if any trials have occurred, scale y-axis down by trial count
            h.hists{n}.BinCounts = h.hists{n}.BinCounts./elapsedSum;
            
            % convert from spikes/bin to spikes/s
            h.hists{n}.BinCounts = h.hists{n}.BinCounts./(h.binSize);
        end
        
        % change colour to black
        h.hists{n}.EdgeColor=[0 0 0];

        % increase the rescale bound if necessary
        if max(h.hists{n}.BinCounts)>h.hMax
            h.hMax = max(h.hists{n}.BinCounts)*1.1;
        end

    % %%%% >1 curves, showing all param 2 values
    else
        % apply color order
        ax = gca;
        ax.ColorOrder = newCO;
        % draw curves
        hold on
        for n2 = 1:h.numCurves
            mask = (h1.stimIdxs(:,h.param1)==n) & (h1.stimIdxs(:,h.param2) == n2);
            h.spiketrain{n,n2} = sort([h1.spikedata{ch,mask,:}]);
            
            h.hists{n,n2} = histogram(h.spiketrain{n,n2},h.tMin:h.binSize:h.tMax, ...
                'DisplayStyle','stairs'); % TODO: custom bin size and time window
            elapsedSum = sum(h1.stimElapsed(mask));
            if elapsedSum>0 
                % if any trials have occurred, scale y-axis down by trial count
                h.hists{n,n2}.BinCounts = h.hists{n,n2}.BinCounts./elapsedSum;
                
                % convert from spikes/bin to spikes/s
                h.hists{n,n2}.BinCounts = h.hists{n,n2}.BinCounts./(h.binSize);
            end
            
            % increase the rescale bound if necessary
            if max(h.hists{n,n2}.BinCounts)>h.hMax
                h.hMax = max(h.hists{n,n2}.BinCounts)*1.1;
            end
        end        
        hold off
    end
    % label
    param1Label = h1.stimLabels{h.param1};
    labelstr = [param1Label,' ',num2str(h1.stimVals(h.param1,n))];
    title(labelstr);
    
    % raster curves
    if h1.rasterCheck.Value
        % subplotidx = ceil(n/xplots)*xplots+n; % every other row w/o PSTHs
        % subplot(yplots*2,xplots,subplotidx);
        pos(1) = mod(n-1,xplots)*wwidthp/xplots + (1-wwidthp);
        pos(2) = (1+wwidthp)/2-wheightp/yplots*ceil(n/xplots);
        pos(3) = wwidthp/xplots*0.75;
        pos(4) = wheightp/yplots*0.2;
        subplot('Position',pos);
        
        % %%%% single stim
        if (h1.param2Select.Value==1 || h1.param2ValSelect.Value>1)
            % draw invisible data first, just to produce plot
            h.rasters{n} = plot(0,0,'k.');
            % use same mask from spiketrain calculation,
            % only difference is each trial's spiketrain isnt being merged
            spikesMasked = h1.spikedata(ch,mask,:);
            
            % randomise stim index order to prevent 'clumping' of rasters
            for elap=1:size(spikesMasked,3)
                for stim=randperm(size(spikesMasked,2))
                    if ~isempty(spikesMasked{1,stim,elap})
                        h.spiketrain2{n}=[h.spiketrain2{n},spikesMasked{1,stim,elap}];
                        h.tc{n}=[h.tc{n},h.tcnum(n)*ones(1,length(spikesMasked{1,stim,elap}))];
                        h.tcnum(n) = h.tcnum(n)+1;
                    end
                end
            end
            % h.rasters{n}=plot(h.spiketrain2{n},-h.tc{n},'k.');
            h.rasters{n}.XData = [h.rasters{n}.XData,h.spiketrain2{n}];
            h.rasters{n}.YData = [h.rasters{n}.YData,-h.tc{n}];
        
        % %%%% multiple stims
        else
            % apply color order
            ax = gca;
            ax.ColorOrder = newCO;
            % draw invisible data first, just to produce plot
            hold on
            % use same mask from spiketrain calculation,
            % only difference is each trial's spiketrain isnt being merged
            for n2 = 1:h.numCurves
                h.rasters{n,n2} = plot(0,0,'.');
                mask = (h1.stimIdxs(:,h.param1)==n) & (h1.stimIdxs(:,h.param2) == n2);
                spikesMasked = h1.spikedata(ch,mask,:);
                for stim=1:size(spikesMasked,2)
                    for elap=1:size(spikesMasked,3)
%                 for elap=1:size(spikesMasked,3)
%                     for stim=randperm(size(spikesMasked,2))
                        if ~isempty(spikesMasked{1,stim,elap})
                            h.spiketrain2{n,n2}=[h.spiketrain2{n,n2},spikesMasked{1,stim,elap}];
                            h.tc{n,n2}=[h.tc{n,n2},h.tcnum(n)*ones(1,length(spikesMasked{1,stim,elap}))];
                            h.tcnum(n) = h.tcnum(n)+1;
                        end
                    end
                end
                h.rasters{n,n2}.XData = [h.rasters{n,n2}.XData,h.spiketrain2{n,n2}];
                h.rasters{n,n2}.YData = [h.rasters{n,n2}.YData,-h.tc{n,n2}];
            end
            hold off
        end
        ax=gca;
        if n<=((yplots-1)*xplots)
            ax.XTick=[];
        end
        if max(h.tcnum)>h.rMax
            h.rMax = max(h.tcnum)*1.1;
        end
        ax.YTick=[];
        ax.XLim = [h.tMin,h.tMax];
        ax.YLim = [-h.rMax,-1];
%         ax.YLimMode = 'auto';
    end
end

% rescale and set labels
for n = 1:h.numplots
    ax = h.hists{n}.Parent;
    ax.XLim = [h.tMin,h.tMax];
    ax.YLim = [0 h.hMax];
    if n==((yplots-1)*xplots+1)   % axes label on bottom left subplot
        ax.YLabel.String = 'Firing rate (spikes/s)';
        if h1.rasterCheck.Value
            ax.XTick=[];
        else
            ax.XLabel.String = 'Time';
        end
    elseif n > ((yplots-1)*xplots+1)
        % remove y ticks, leave x ticks (unless xticks drawn under rasters)
        ax.YTick=[];
        if h1.rasterCheck.Value
            ax.XTick=[];
        end
    elseif mod(n,xplots)==1
        % leave y ticks, remove x
        ax.XTick=[];
    else
        % remove all ticks
        ax.XTick=[];
        ax.YTick=[];
    end
end

guidata(f,h);
guidata(f_master,h1);

catch err
    getReport(err)
    keyboard;
end
end

% % ========== UPDATE FUNCTION ============================================
function updateFocusWindow(f)
try
% fetch app data
h = guidata(f);
h1 = guidata(h.figure_master);

if h1.param2Select.Value>1 && h.param2ValIdx>0 && h.param2ValIdx~=h1.thisIdxs(h.param2)
    % this stimulus does not match the selected param 2 value,
    % therefore no need to update plot data. do nothing!
else 
    % interpret current stim
    n = h1.thisIdxs(h.param1);
    mask = h1.stimIdxs(:,h.param1) == n;
    if h1.param2Select.Value>1
        n2 = h1.thisIdxs(h.param2);
        mask = mask & h1.stimIdxs(:,h.param2)==n2;
    end

    % fetch iteration count and spikes of current trial
    elapsedNum = h1.stimElapsed(h1.thisStim);
    thisSpikes = h1.spikedata{h.ch,h1.thisStim,elapsedNum};

    % append new spiketimes to spike train; sort
    if (h1.param2Select.Value==1 || h1.param2ValSelect.Value>1)
        thisSpikes = h1.spikedata{h.ch,h1.thisStim,h1.stimElapsed(h1.thisStim)};
        h.spiketrain{n} = sort([h.spiketrain{n},thisSpikes]);
        
        h.hists{n}.Data = h.spiketrain{n};
        h.hists{n}.BinCounts = h.hists{n}.BinCounts ...
            ./(sum(h1.stimElapsed(mask))* h.binSize);

        % rescale axes if necessary
        if max(h.hists{n}.BinCounts)>h.hMax
            h.hMax = max(h.hists{n}.BinCounts)*1.1;
            for n3 = 1:h.numplots
                ax = h.hists{n3}.Parent;
                ax.YLim = [0 h.hMax];
            end
        end
    else
        thisSpikes = h1.spikedata{h.ch,h1.thisStim,h1.stimElapsed(h1.thisStim)};
        h.spiketrain{n,n2} = sort([h.spiketrain{n,n2},thisSpikes]);
        h.hists{n,n2}.Data = h.spiketrain{n,n2};
        h.hists{n,n2}.BinCounts = h.hists{n,n2}.BinCounts ...
            ./(sum(h1.stimElapsed(mask)) * h.binSize);
        % rescale axes if necessary
        if max(h.hists{n,n2}.BinCounts)>h.hMax
            h.hMax = max(h.hists{n,n2}.BinCounts)*1.1;
            for n3 = 1:h.numplots
                ax = h.hists{n3,1}.Parent;
                ax.YLim = [0 h.hMax];
            end
        end
    end
    % update hist data
    % % === Manually calculate hist values: not used for now 
    % spikesBinned = ceil(h.spiketrain{n}./h.binSize);
    % for bin = 1:h.hists{n}.NumBins
    %     h.hists{n}.Values = sum(spikesBinned == bin);
    % end
    % % ====================================================
    
    
    % raster curves
    if h1.rasterCheck.Value
        if (h1.param2Select.Value==1 || h1.param2ValSelect.Value>1)
    %         h.spiketrain2{n}=[h.spiketrain2{n},spikesMasked{1,stim,elap}];
    %         h.tc{n}=[h.tc{n},h.tcnum(n)*ones(1,length(spikesMasked{1,stim,elap}))];
    %         h.tcnum(n) = h.tcnum(n)+1;
            h.rasters{n}.XData = [h.rasters{n}.XData,thisSpikes];
            h.rasters{n}.YData = [h.rasters{n}.YData,-h.tcnum(n)*ones(1,length(thisSpikes))];
            h.tcnum(n) = h.tcnum(n)+1;
        else
            h.rasters{n,n2}.XData = [h.rasters{n,n2}.XData,thisSpikes];
            h.rasters{n,n2}.YData = [h.rasters{n,n2}.YData,-h.tcnum(n)*ones(1,length(thisSpikes))];
            h.tcnum(n) = h.tcnum(n)+1;
        end
        if max(h.tcnum)>h.rMax
            h.rMax = max(h.tcnum)*1.1;
            for iplot = 1:h.numplots
                ax = h.rasters{iplot}.Parent;
                ax.YLim = [-h.rMax,-1];
            end
        end
    end
    guidata(f,h);
end
catch
end
end

% % ========== CLOSE FUNCTION =============================================
function closeFocusWindow(f,~)
% clear Focus flag in handles structure so GUI no longer tries to update it

h = guidata(f);
h1= guidata(h.figure_master);

h1.figure_focus{h.ch}=[];
h1.figure_focusMat(h.ch)=0;
guidata(h.figure_master,h1);

% then close figure
delete(f);
end