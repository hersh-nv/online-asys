function f = focusWindowSwitchyard
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

fprintf('Focusing on Channel %g!\n',ch);

% initialise handles, fetch master handles
h = struct;
h.figure_master = f_master;
h1 = guidata(f_master);

% create figure, save to handles
titlestr = sprintf('Channel %g',ch);
f = figure('Name',titlestr,'NumberTitle','off');
h.figure1 = f;
h1.figure_focus{ch}=f;

% set figure position and other properties
f.CloseRequestFcn = @closeFocusWindow;

% save some data to handles
h.ch = ch;
h.binSize = 0.05; % (s)
h.hMax = 20*h.binSize;
h.param1 = h1.param1Select.Value;

% start drawing subplots
h.numplots = h1.nStim(h.param1);
yplots = round(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);

h.spiketrain{h.numplots} = [];

for iplot = 1:h.numplots
    subplot(yplots,xplots,iplot);
        
    mask = h1.stimIdxs(:,h.param1) == iplot;
    h.spiketrain{iplot} = sort([h1.spikedata{ch,mask,:}]);
    
    h.hists{iplot} = histogram(h.spiketrain{iplot},0:h.binSize:1, ...
        'DisplayStyle','stairs'); % TODO: custom bin size and time window
    elapsedSum = sum(h1.stimElapsed(mask));
    if elapsedSum>0 % if any trials have occurred, scale y-axis down by trial count
        h.hists{iplot}.BinCounts = h.hists{iplot}.BinCounts./elapsedSum;
    end
    
    % rescale all axes if necessary
    if max(h.hists{iplot}.BinCounts)>h.hMax
        h.hMax = max(h.hists{iplot}.BinCounts)*1.1;
        for iplot2 = 1:iplot
            ax = h.hists{iplot2}.Parent;
            ax.YLim = [0 h.hMax];
        end
    else % just scale this one
        ax = h.hists{iplot}.Parent;
        ax.YLim = [0 h.hMax];
    end
    
    % label
    param1Label = h1.stimLabels{h.param1};
    labelstr = [param1Label,' ',num2str(h1.stimVals(h.param1,iplot))];
    title(labelstr);
%     ylim=get(ax,'yLim');
%     text(0.05,ylim(2)*0.9,labelstr);
end

guidata(f,h);
guidata(f_master,h1);

end

% % ========== UPDATE FUNCTION ============================================
function updateFocusWindow(f)
% fetch app data
h = guidata(f);
h1 = guidata(h.figure_master);

% interpret current stim
iplot = h1.thisIdxs(h.param1);
mask = h1.stimIdxs(:,h.param1) == iplot;

% fetch iteration count and spikes of current trial
elapsedNum = h1.stimElapsed(h1.thisStim);
thisSpikes = h1.spikedata{h.ch,h1.thisStim,elapsedNum};

% append new spiketimes to spike train; sort
h.spiketrain{iplot} = sort([h.spiketrain{iplot},h1.spikedata{h.ch,h1.thisStim,:}]);

% update hist data
% % === Manually calculate hist values: not used for now 
% spikesBinned = ceil(h.spiketrain{n}./h.binSize);
% for bin = 1:h.hists{n}.NumBins
%     h.hists{n}.Values = sum(spikesBinned == bin);
% end
% % ====================================================
h.hists{iplot}.Data = h.spiketrain{iplot};
h.hists{iplot}.BinCounts = h.hists{iplot}.BinCounts./sum(h1.stimElapsed(mask));

% rescale axes if necessary
if max(h.hists{iplot}.BinCounts)>h.hMax
    h.hMax = max(h.hists{iplot}.BinCounts)*1.1;
    for iplot = 1:h.numplots
        ax = h.hists{iplot}.Parent;
        ax.YLim = [0 h.hMax];
    end
end

guidata(f,h);
end

% % ========== CLOSE FUNCTION =============================================
function closeFocusWindow(f,~)
% clear Focus flag in handles structure so GUI no longer tries to update it
h = guidata(f);
h1= guidata(h.figure_master);

h1.figure_focus{h.ch}=[];
guidata(h.figure_master,h1);

% then close figure
delete(f);
end