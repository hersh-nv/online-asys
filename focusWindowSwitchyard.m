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
try
fprintf('Focusing on Channel %g!\n',ch);

% initialise handles, fetch master handles
h = struct;
h.figure_master = f_master;
h1 = guidata(f_master);

% create figure, save to handles
titlestr = sprintf('Channel %g',ch);
if h1.focusSettings.singletonCheck
    for existingFocus = find(h1.figure_focusMat)
        closeFocusWindow(h1.figure_focus{existingFocus});
    end
end
f = figure('Name',titlestr,'NumberTitle','off');
h.figure1 = f;
h1.figure_focus{ch}=f;
h1.figure_focusMat(ch)=1;

% set figure position and other properties
f.CloseRequestFcn = @closeFocusWindow;

% save some data to handles
h.ch = ch;
h.binSize = h1.focusSettings.psthBinSize/1000; % (s)
h.hMax = 20*h.binSize;
h.param1 = h1.param1Select.Value;
h.param2 = find(strcmp(h1.param2Select.String{h1.param2Select.Value},h1.stimLabels));
param2Val = str2double(h1.param2ValSelect.String{h1.param2ValSelect.Value});
if isnan(param2Val)
    h.param2ValIdx = 0;
else
    h.param2ValIdx = find(param2Val==h1.stimVals(h.param2,:));
end

% start drawing subplots
h.numplots = h1.nStim(h.param1);
yplots = round(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);

if (h1.param2Select.Value==1 || h1.param2ValSelect.Value>1)
    h.spiketrain{h.numplots} = [];
else
    h.numCurves = h1.nStim(h.param2);
    h.spiketrain{h.numplots,h.numCurves} = [];
    % new colour order
    newCO=[linspace(0,1,h.numCurves)', ...
        zeros(h.numCurves,1), ...
        linspace(1,0,h.numCurves)'];
end

for n = 1:h.numplots
    subplot(yplots,xplots,n);
    
    % %%%% single curve
    if (h1.param2Select.Value==1 || h1.param2ValSelect.Value>1)
        mask = h1.stimIdxs(:,h.param1) == n;
        if h1.param2ValSelect>1
            mask = mask & h1.stimIdxs(:,h.param2) == h.param2ValIdx;
        end
        h.spiketrain{n} = sort([h1.spikedata{ch,mask,:}]);

        h.hists{n} = histogram(h.spiketrain{n},0:h.binSize:1, ...
            'DisplayStyle','stairs'); % TODO: custom bin size and time window
        elapsedSum = sum(h1.stimElapsed(mask));
        if elapsedSum>0 % if any trials have occurred, scale spikenum down by trial count
            h.hists{n}.BinCounts = h.hists{n}.BinCounts./elapsedSum;
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
            
            h.hists{n,n2} = histogram(h.spiketrain{n,n2},0:h.binSize:1, ...
                'DisplayStyle','stairs'); % TODO: custom bin size and time window
            elapsedSum = sum(h1.stimElapsed(mask));
            if elapsedSum>0 % if any trials have occurred, scale spikenum down by trial count
                h.hists{n,n2}.BinCounts = h.hists{n,n2}.BinCounts./elapsedSum;
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
end

% rescale and set labels
for n = 1:h.numplots
    ax = h.hists{n}.Parent;
    ax.YLim = [0 h.hMax];
    if n==((yplots-1)*xplots+1)   % axes label on bottom left subplot
        ax.YLabel.String = 'Firing rate (spikes/bin)';
        ax.XLabel.String = 'Time';
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
        h.spiketrain{n} = sort([h.spiketrain{n},h1.spikedata{h.ch,h1.thisStim,:}]);
        
        h.hists{n}.Data = h.spiketrain{n};
        h.hists{n}.BinCounts = h.hists{n}.BinCounts./sum(h1.stimElapsed(mask));

        % rescale axes if necessary
        if max(h.hists{n}.BinCounts)>h.hMax
            h.hMax = max(h.hists{n}.BinCounts)*1.1;
            for n3 = 1:h.numplots
                ax = h.hists{n3}.Parent;
                ax.YLim = [0 h.hMax];
            end
        end
    else
        h.spiketrain{n,n2} = sort([h.spiketrain{n,n2},h1.spikedata{h.ch,h1.thisStim,:}]);
        h.hists{n,n2}.Data = h.spiketrain{n,n2};
        h.hists{n,n2}.BinCounts = h.hists{n,n2}.BinCounts./sum(h1.stimElapsed(mask));
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
    
    guidata(f,h);
end
end

% % ========== CLOSE FUNCTION =============================================
function closeFocusWindow(f,~)
% clear Focus flag in handles structure so GUI no longer tries to update it
try
h = guidata(f);
h1= guidata(h.figure_master);

h1.figure_focus{h.ch}=[];
h1.figure_focusMat(h.ch)=0;
guidata(h.figure_master,h1);
catch
end
% then close figure
delete(f);
end