function h = startTuningAll(h)
% startTuningAll(handles) initialises the tuning curves in the
% GUI_Online_PlotAll figure. handles is a struct that contains all the
% handles and userdata for this GUI.
%
% HN May 2018
%
% See also GUI_ONLINE_PLOTALL, GUIDATA

h1 = guidata(h.figure_master);

% h.numplots = 32; % hardcoded just for now
h.numplots = h1.maxChO-h1.minChO + 1;

yplots = round(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);

figure(h.figure1);      % draw into figure_plotAll
h.axes{1,h.numplots}=[];

param1 = h1.param1Select.Value;


h.spikerate = h1.spikerate;

h.tuning = nan(h.numplots,h1.nStim(param1));

h.param2 = find(strcmp(h1.param2Select.String{h1.param2Select.Value},h1.stimLabels));
param2Idx = str2double(h1.param2ValSelect.String{h1.param2ValSelect.Value});
if isnan(param2Idx)
    h.param2Val = 0;
else
    h.param2Val = find(param2Idx==h1.stimVals(h.param2,:));
end

if h1.param2Select.Value > 1       % Param 2 selected
    if h.param2Val == 0             % "Show all"
        numCurves = h1.nStim(h.param2);
        h.tuning = repmat(h.tuning,[1 1 numCurves]);
    end 
end

for iplot=1:h.numplots
    % create and save handles to axes and lineplot separately
    h.axes{iplot} = subplot(yplots,xplots,iplot);
    if h1.param2Select.Value>1 && h.param2Val == 0             % "Show all"
        for iCurve = 1:numCurves
            h.lines{iplot,iCurve} = plot(h.tuning(iplot,:),'-.','MarkerSize',10);
        end
    else
        h.lines{iplot} = plot(h.tuning(iplot,:),'-k.','MarkerSize',10);
    end
    
    % attach Focus callback
    h.axes{iplot}.ButtonDownFcn = {@openFocusWindow,iplot,h.figure_master};
    
    % adjust axes appearance
    h.axes{iplot}.XLimMode = 'auto';
    h.axes{iplot}.YLimMode = 'auto';
    
    if iplot==((yplots-1)*xplots+1)   % axes label on bottom left subplot
        h.axes{iplot}.YLabel.String = 'Firing rate (spikes/s)';
        h.axes{iplot}.XLabel.String = h1.stimLabels{param1};
    end
end

% create plot update timer

h.drawAllTimer = timer('Period',h1.drawUpdatePeriod,...
    'TimerFcn',{@updateTuningAll,h.figure1},...
    'BusyMode','queue', ...
    'ExecutionMode','fixedRate',...
    'StartDelay',0.5 ...
    );
start(h.drawAllTimer);

% note: no final call to guidata to save handles structure, instead it is
% just passed back to GUI_Online_PlotAll_OpeningFcn, which adds other data
% to handles before saving it
end

%% timer callback
function updateTuningAll(~,~,f)
% Callback function for drawAllTimer. On every call, it recalculates tuning
% data for every channel (using spike data in h.spikedata) and updates the
% channel overview figure accordingly.

try 
    tuningsw = tic; % tuning stopwatch
    % fetch both handles
    h = guidata(f);
    h1 = guidata(h.figure_master);
    
    if h1.param2Select.Value>1 && h.param2Val>0 && h.param2Val~=h1.thisIdxs(h.param2)
        % skip!
        else

        % retrieve mask for all conditions that match this one in param 1 value
        param1 = h1.param1Select.Value;
        n = h1.thisIdxs(param1);
        mask = h1.stimIdxs(:,param1)==n;

        % retrieve spikes and repetition count for this particular condition
        elapsedMask = h1.stimElapsed(h1.thisStim);
        spikesMasked = h1.spikedata(h1.minChO:h1.maxChO,h1.thisStim,elapsedMask);

    %     % fill spikerate with NaNs as it increases
    %     [srx,sry,srz] = size(h.spikerate);
    %     if elapsedMask>srz
    %         h.spikerate(:,:,srz+1:elapsedMask) = nan(srx,sry);
    %     end

        % calculate spikerate for this stim, then retrieve all spikerates in mask
        h.spikerate(h1.minChO:h1.maxChO,h1.thisStim,elapsedMask) = cellfun(@(x) sum(x>=h1.tmin & x<=h1.tmax),spikesMasked)./(h1.tmax-h1.tmin);
        spikerateMasked = h.spikerate(h1.minChO:h1.maxChO,mask,:);

        if h1.param2Select.Value == 1   % 'All': average across all other params
            h.tuning(:,n) = mean(mean(spikerateMasked,3),2,'omitnan');
        else
            % produce second-order mask (i.e. all conditions in current mask that
            % match current condition in param 2 value)
            stimIdxsMasked = h1.stimIdxs(mask,:);
            n2 = h1.thisIdxs(h.param2);
            mask2 = stimIdxsMasked(:,h.param2) == n2;

            % apply second-order mask
            spikerateMasked2 = spikerateMasked(h1.minChO:h1.maxChO,mask2,:);

            if (h.param2Val==0) % "Show all"
                h.tuning(:,n,n2) = mean(mean(spikerateMasked2,3),2,'omitnan');
            else
                h.tuning(:,n) = mean(mean(spikerateMasked2,3),2,'omitnan');
            end
        end
        stopwatch(1) = toc(tuningsw)*1e3;

        if h1.param2Select.Value>1 && h.param2Val == 0
            tunedidxs = find(~isnan(h.tuning(1,:,n2)));
        else
            tunedidxs = find(~isnan(h.tuning(1,:)));
        end

        for iplot = 1 : h.numplots
            if h1.param2Select.Value>1 && h.param2Val == 0
                h.lines{iplot,n2}.XData = h1.stimVals(param1,tunedidxs);
                h.lines{iplot,n2}.YData = h.tuning(iplot,tunedidxs,n2);
            else
                h.lines{iplot}.XData = h1.stimVals(param1,tunedidxs);
                h.lines{iplot}.YData = h.tuning(iplot,tunedidxs);
            end

            h.axes{iplot}.XLim = [min(h1.stimVals(param1,:)),Inf];
            h.axes{iplot}.YLimMode = 'auto';
            h.axes{iplot}.YLim(1) = 0;
        end
        
        stopwatch(2) = toc(tuningsw)*1e3;
        guidata(h.figure1,h);
        guidata(h1.figure1,h1);
        if (h1.verbose)
            fprintf("Overview | t = %f, %f, %f\n",stopwatch(1),stopwatch(2),toc(tuningsw)*1e3);
        end
    end
catch err
    getReport(err)
    keyboard;
end

end