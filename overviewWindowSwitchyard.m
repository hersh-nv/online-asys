function f = overviewWindowSwitchyard()
% f = overviewWindowSwitchyard() creates a switchyard object with
%       child functions to create or control the Overview window:
%
%       f.open(~,~,f_master) creates an Overview window with tuning curves
%           visualising the currently acquired spike data. f_master is the
%           handle to the Master window of the GUI.
%       f.update(f) updates an Overview figure f.
%       f.close(f)  closes an Overview figure f and clears the associated
%           tuning data.
%
%       HN - July 2018

f.open = @openOverviewWindow;
f.update = @updateOverviewWindow;
f.close = @closeOverviewWindow;
end


% % ========== INITIALISATION FUNCTION ====================================
function openOverviewWindow(f_master)

try

% initialise overview handles, fetch master handles
h = struct;
h.figure_master = f_master;
h1 = guidata(f_master);

% create figure, and save its handles
if ishandle(h1.figure_overview)
    f = figure(h1.figure_overview);
    clf;
else
    f = figure('Name','Channel Overview','NumberTitle','Off');
    % set figure position and other properties
    f.CloseRequestFcn = @closeOverviewWindow;
    res = get(groot, 'Screensize');
    % NOTE: positioning is a bit finicky and it seems like OuterPosition takes
    % into account some misc Windows 10 UI elements of unknown size. haven't
    % yet found a more reliable way to tile windows to occupy 100% of desktop
    % space while leaving room for Windows taskbar, startbar, etc...
    f.OuterPosition = f_master.OuterPosition;  % initialise to same position as master
    f.OuterPosition(1) = f_master.Position(3); % then shift to right 85% of screen
    f.OuterPosition(3) = res(3)-f.OuterPosition(1)+7;
    wwidth = f.Position(3);
    wheight= f.Position(4);
end
h.figure1 = f;
h1.figure_overview=f;



% disable Overview settings until Overview is closed ?
% TODO: leave them enabled; if they are changed while overview is open,
% overview window should be cleared and redrawn without user having to
% close it. probably add a .clear() method to the switchyard
% h1.channelInput.Enable = 'Off';
% h1.timeWinInput.Enable = 'Off';
% h1.param1Select.Enable = 'Off';
% h1.param2Select.Enable = 'Off';
% h1.param2ValSelect.Enable = 'Off';


% save some data to handles
h.param1 = h1.param1Select.Value;
h.param2 = find(strcmp(h1.param2Select.String{h1.param2Select.Value},h1.stimLabels));
param2Val = str2double(h1.param2ValSelect.String{h1.param2ValSelect.Value});
if isnan(param2Val)
    h.param2ValIdx = 0;
else
    h.param2ValIdx = find(param2Val==h1.stimVals(h.param2,:));
end
h.numplots = h1.maxChO-h1.minChO + 1;
h.spikerate = h1.spikerate; % copy empty array of correct size
h.tuning = nan(h.numplots,h1.nStim(h.param1));
h.tuningSD = zeros(h.numplots,h1.nStim(h.param1));
if h1.param2Select.Value > 1       % Param 2 selected
    if h.param2ValIdx == 0             % "Show all"
        numCurves = h1.nStim(h.param2);
        h.tuning = repmat(h.tuning,[1 1 numCurves]);
        h.tuningSD = repmat(h.tuningSD,[1 1 numCurves]);
        
        % new colour order
        newCO=[linspace(0,1,numCurves)', ...
            zeros(numCurves,1), ...
            linspace(1,0,numCurves)'];
    end 
end

% start drawing subplots
yplots = round(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);

wwidthp=0.95; % proportional window width and
wheightp=0.9; % height for the subplots to be drawn inside
for iplot=1:h.numplots
    % create and save handles to axes and lineplot separately
    pos(1) = mod(iplot-1,xplots)*wwidthp/xplots + (1-wwidthp);
    pos(2) = (1+wwidthp)/2-wheightp/yplots*ceil(iplot/xplots);
    pos(3) = wwidthp/xplots*0.75;
    pos(4) = wheightp/yplots*0.9;
    h.axes{iplot} = subplot('Position',pos);
    if h1.param2Select.Value>1 && h.param2ValIdx == 0             % "Show all"
        % apply color order
        h.axes{iplot}.ColorOrder = newCO;
        % draw each curve
        hold on
        for iCurve = 1:numCurves
            if h1.ebCheck.Value
                h.lines{iplot,iCurve} = errorbar(h.tuning(iplot,:,iCurve), ...
                    h.tuningSD(iplot,:,iCurve), ...
                    'CapSize',0, ...
                    'Marker','.', ...
                    'MarkerSize',5);
            else
                h.lines{iplot,iCurve} = plot(h.tuning(iplot,:,iCurve), ...
                    'Marker','.', ...
                    'MarkerSize',5);
            end
        end
        hold off
    else
        if h1.ebCheck.Value
            h.lines{iplot} = errorbar(h.tuning(iplot,:), ...
                h.tuningSD(iplot,:), ...
                '-k.',...
                'CapSize',0, ...
                'MarkerSize',10);
        else
            h.lines{iplot} = plot(h.tuning(iplot,:),'-k.','MarkerSize',10);
        end
    end
    
    % attach Focus callback
    focusWindow = focusWindowSwitchyard();
    h.axes{iplot}.ButtonDownFcn = {focusWindow.open,h.figure_master,iplot};
    
    if iplot==((yplots-1)*xplots+1)   % axes label on bottom left subplot
        h.axes{iplot}.YLabel.String = 'Firing rate (spikes/s)';
        h.axes{iplot}.XLabel.String = h1.stimLabels{h.param1};
    end
    if ceil(iplot/xplots)~=yplots    % x axis ticks on bottom edge
        h.axes{iplot}.XTick=[];
    end
end

% calculate spikerates
            % % % h.spikerate = cellfun(@(x) sum(x>=h1.tmin &
            % x<=h1.tmax),h1.spikedata)./(h1.tmax-h1.tmin);
            %
            % cellfun is, for some reason, incredibly slow for this task.
            % hence the for loops, which are ~100x faster. could implement
            % a cellfun2 fcn to do the below instead
h.spikerate = zeros(size(h1.spikedata));
for stim = 1:size(h1.spikedata,2)
for elap = 1:size(h1.spikedata,3)
    if elap>h1.stimElapsed(stim)
        h.spikerate(:,stim,elap) = nan;
    else
        for ch = h1.minChO:h1.maxChO
            spikes=h1.spikedata{ch,stim,elap};
            h.spikerate(ch,stim,elap) = sum(spikes>=h1.tmin & spikes<h1.tmax);
        end        
    end
end
end
h.spikerate = h.spikerate/(h1.tmax-h1.tmin);

% calculate averages to find tuning preferences
for n=1:h1.nStim(h.param1)
    if h1.param2Select.Value == 1   % 'All': average across all other params
        % find spikerates for this param value
        mask = h1.stimIdxs(:,h.param1)==n;
        srMasked = h.spikerate(h1.minChO:h1.maxChO,mask,:);
        % reshape to collapse repetitions into different stim conds
        srMasked = reshape(srMasked,size(srMasked,1),[]);
        % average and std
        h.tuning(:,n) = mean(srMasked,2,'omitnan');
        if h1.ebCheck.Value
            h.tuningSD(:,n) = std(srMasked,0,2,'omitnan');
        end
    elseif h1.param2Select.Value>1 && h.param2ValIdx==0 % Param 2 selected: 'All'
        % param 2 value (n2) defines another condition for the mask
        for n2 = 1:h1.nStim(h.param2)
            % find spikerates for these param values
            mask = (h1.stimIdxs(:,h.param1)==n) & (h1.stimIdxs(:,h.param2)==n2);
            srMasked = h.spikerate(h1.minChO:h1.maxChO,mask,:);
            % reshape to collapse repetitions into different stim conds
            srMasked = reshape(srMasked,size(srMasked,1),[]);
            % average and std
            h.tuning(:,n,n2) = mean(srMasked,2,'omitnan');
            if h1.ebCheck.Value
                h.tuningSD(:,n,n2) = std(srMasked,0,2,'omitnan');
            end
        end
    else  % Param 2 selected and val selected
        % param 2 value (n2) defines another condition for the mask
        n2 = h.param2ValIdx;
        % find spikerates for these param values
        mask = (h1.stimIdxs(:,h.param1)==n) & (h1.stimIdxs(:,h.param2)==n2);
        srMasked = h.spikerate(h1.minChO:h1.maxChO,mask,:);
        % reshape to collapse repetitions into different stim conds
        srMasked = reshape(srMasked,size(srMasked,1),[]);
        % average and std
        h.tuning(:,n) = mean(mean(srMasked,3,'omitnan'),2,'omitnan');
        if h1.ebCheck.Value
            h.tuningSD(:,n) = std(srMasked,0,2,'omitnan');
        end
    end
end
if ~(h1.param2Select.Value>1 && h.param2ValIdx == 0)
    tunedidxs = find(~isnan(h.tuning(1,:)));
end

% draw tuning preferences into plots
for iplot = 1 : h.numplots
    if h1.param2Select.Value>1 && h.param2ValIdx == 0
        for n2 = 1:h1.nStim(h.param2)
            tunedidxs = find(~isnan(h.tuning(1,:,n2)));
            h.lines{iplot,n2}.XData = h1.stimVals(h.param1,tunedidxs);
            h.lines{iplot,n2}.YData = h.tuning(iplot,tunedidxs,n2);
            if h1.ebCheck.Value
                h.lines{iplot,n2}.YPositiveDelta = h.tuningSD(iplot,tunedidxs,n2);
                h.lines{iplot,n2}.YNegativeDelta = h.tuningSD(iplot,tunedidxs,n2);
            end
        end
    else
        h.lines{iplot}.XData = h1.stimVals(h.param1,tunedidxs);
        h.lines{iplot}.YData = h.tuning(iplot,tunedidxs);
        if h1.ebCheck.Value
            h.lines{iplot}.YPositiveDelta = h.tuningSD(iplot,tunedidxs);
            h.lines{iplot}.YNegativeDelta = h.tuningSD(iplot,tunedidxs);
        end
    end
    
    % adjust axes appearance
    h.axes{iplot}.XLim = [min(h1.stimVals(h.param1,:)),Inf];
    if h1.yScaleAutoCheck.Value
        h.axes{iplot}.YLimMode = 'auto';
        if h1.yScaleUniformCheck.Value
            % store y lims, to scale all axes by max ylim later
            h.YLims(iplot)=h.axes{iplot}.YLim(2);
        end
    else
        h.axes{iplot}.YLim = [h1.overviewSettings.yMin, ...
                              h1.overviewSettings.yMax];
    end
end
if h1.yScaleAutoCheck.Value && h1.yScaleUniformCheck.Value
    for iplot=1:h.numplots
        h.axes{iplot}.YLim = [0,max(h.YLims)];
    end
end


% save all app data
guidata(f,h);
guidata(f_master,h1);

catch err
    getReport(err)
    keyboard;
end
end


% % ========== UPDATE FUNCTION ============================================
function updateOverviewWindow(f)
try 
% fetch both handles
h = guidata(f);
h1 = guidata(h.figure_master);

if h1.param2Select.Value>1 && h.param2ValIdx>0 && h.param2ValIdx~=h1.thisIdxs(h.param2)
    % this stimulus does not match the selected param 2 value,
    % therefore no need to update plot data. do nothing!
else
    % retrieve spikes and repetition count for this particular condition
    elapsedNum = h1.stimElapsed(h1.thisStim);
    thisSpikes = h1.spikedata(h1.minChO:h1.maxChO,h1.thisStim,elapsedNum);
    
    % fill spikerate with nans as it expands; nans distinguish between
    % non-elapsed trials vs. elapsed trials with 0 spikerate
    if elapsedNum > size(h.spikerate,3)
        [sry, srx, ~] = size(h.spikerate);
        h.spikerate(:,:,elapsedNum)=nan(sry,srx);
    end
    
    % calculate spikerate for this stim
    for ch = h1.minChO:h1.maxChO
        h.spikerate(ch,h1.thisStim,elapsedNum) = sum(thisSpikes{ch}>=h1.tmin & thisSpikes{ch}<h1.tmax);
    end

    % average spikerates to calculate parameter preference / tuning
    if h1.param2Select.Value == 1
        % average across all non-1 params
        % mask: idx of all stims with same param 1 value as current stim
        n = h1.thisIdxs(h.param1);
        mask = h1.stimIdxs(:,h.param1)==n;
        % retrieve all spikerates in mask
        srMasked = h.spikerate(h1.minChO:h1.maxChO,mask,:);
        % reshape to collapse repetitions into different stim conds
        srMasked = reshape(srMasked,size(srMasked,1),[]);
        % average and std
        h.tuning(:,n) = mean(srMasked,2,'omitnan');
        if h1.ebCheck.Value
            h.tuningSD(:,n) = std(srMasked,0,2,'omitnan');
        end
    else
        % mask is idx of all stims with the same param 1 and param 2 value
        % as current stim
        n = h1.thisIdxs(h.param1);
        n2 = h1.thisIdxs(h.param2);
        mask = h1.stimIdxs(:,h.param1)==n & h1.stimIdxs(:,h.param2)==n2;
        % retrieve all spikerates in mask
        srMasked = h.spikerate(h1.minChO:h1.maxChO,mask,:);
        % reshape to collapse repetitions into different stim conds
        srMasked = reshape(srMasked,size(srMasked,1),[]);
        if (h.param2ValIdx==0) % "Show all"
            h.tuning(:,n,n2) = mean(mean(srMasked,3,'omitnan'),2,'omitnan');
            if h1.ebCheck.Value
                h.tuningSD(:,n,n2) = std(srMasked,0,2,'omitnan');
            end
        else
            h.tuning(:,n) = mean(mean(srMasked,3,'omitnan'),2,'omitnan');
            if h1.ebCheck.Value
                h.tuningSD(:,n) = std(srMasked,0,2,'omitnan');
            end
        end
    end
    
    % mask off stim conditions that haven't elapsed yet from the graph
    if h1.param2Select.Value>1 && h.param2ValIdx == 0
        tunedidxs = find(~isnan(h.tuning(1,:,n2)));
    else
        tunedidxs = find(~isnan(h.tuning(1,:)));
    end
    
    % update tuning curve plots
    for iplot = 1 : h.numplots
        if h1.param2Select.Value>1 && h.param2ValIdx == 0
            h.lines{iplot,n2}.XData = h1.stimVals(h.param1,tunedidxs);
            h.lines{iplot,n2}.YData = h.tuning(iplot,tunedidxs,n2);
            if h1.ebCheck.Value
                h.lines{iplot,n2}.YPositiveDelta = h.tuningSD(iplot,tunedidxs,n2);
                h.lines{iplot,n2}.YNegativeDelta = h.tuningSD(iplot,tunedidxs,n2);
            end
        else
            h.lines{iplot}.XData = h1.stimVals(h.param1,tunedidxs);
            h.lines{iplot}.YData = h.tuning(iplot,tunedidxs);
            if h1.ebCheck.Value
                h.lines{iplot}.YPositiveDelta = h.tuningSD(iplot,tunedidxs);
                h.lines{iplot}.YNegativeDelta = h.tuningSD(iplot,tunedidxs);
            end
        end

        h.axes{iplot}.XLim = [min(h1.stimVals(h.param1,:)),Inf];
        if h1.yScaleAutoCheck.Value
            h.axes{iplot}.YLimMode = 'auto';
            if h1.yScaleUniformCheck.Value
                h.YLims(iplot)=h.axes{iplot}.YLim(2);
            end
        else
            h.axes{iplot}.YLim = [h1.overviewSettings.yMin, ...
                                  h1.overviewSettings.yMax];
        end
    end
    if h1.yScaleAutoCheck.Value && h1.yScaleUniformCheck.Value
        for iplot=1:h.numplots
            h.axes{iplot}.YLim = [0,max(h.YLims)];
        end
    end

    guidata(h.figure1,h);
    guidata(h1.figure1,h1);
end
catch err
    getReport(err)
    keyboard;
end
end


% % ========== CLOSE FUNCTION =============================================
function closeOverviewWindow(f,~)
% reenable Overview settings
h = guidata(f);
h1 = guidata(h.figure_master);
try
    h1.channelInput.Enable = 'On';
    h1.timeWinInput.Enable = 'On';
    h1.param1Select.Enable = 'On';
    h1.param2Select.Enable = 'On';
    if h1.param2Select.Value>1
        h1.param2ValSelect.Enable = 'On';
    end
catch
    keyboard;
end
% then close figure
delete(f);
end
