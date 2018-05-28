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
h.numplots = h1.maxCh-h1.minCh + 1;

yplots = floor(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);

figure(h.figure1);      % draw into figure_plotAll
h.axes{1,h.numplots}=[];

param1 = h1.param1Select.Value;

for iplot=1:h.numplots
    % create and save handles to axes and lineplot separately
    h.axes{iplot} = subplot(yplots,xplots,iplot);
    h.lines{iplot} = plot(1:h1.nStim(param1),zeros(1,h1.nStim(param1)));
    
    % adjust axes appearance
    h.axes{iplot}.XLim = [1 h1.nStim(param1)];
    h.axes{iplot}.YLimMode = 'auto';
    h.axes{iplot}.YLim(1) = 0;
    h.axes{iplot}.XTick=[];
    h.axes{iplot}.YTick=[];
end

% create plot update timer

h.drawAllTimer = timer('Period',h1.drawUpdatePeriod,...
    'TimerFcn',{@updateTuningAll,h},...
    'ExecutionMode','fixedSpacing'...
    );
start(h.drawAllTimer);

% note: no final call to guidata to save handles structure, instead it is
% just passed back to GUI_Online_PlotAll_OpeningFcn, which adds other data
% to handles before saving it
end

%% timer callback
function updateTuningAll(~,~,h)
% Callback function for drawAllTimer. On every call, it recalculates tuning
% data for every channel (using spike data in h.spikedata) and updates the
% channel overview figure accordingly.

tic;

% fetch master handles, where spikedata is stored
h1 = guidata(h.figure_master);

param1 = h1.param1Select.Value;
param1str = h1.stimLabels{param1};

try 
    for n = 1:h1.nStim(param1)
        mask = h1.stimIdxs(:,param1)==n;
        spikesMasked = h1.spikedata(:,mask,:);
        elapsedMask = h1.stimElapsed(mask);
        
        spikeSum(:,:) = sum(cellfun(@(x) sum(x>=h1.tmin & x<=h1.tmax),spikesMasked),3);
        tuningTmp = spikeSum./(repmat(elapsedMask',[size(spikeSum,1),1])*(h1.tmax-h1.tmin));
        
        % if averaging across other params
        tuning(:,n) = mean(tuningTmp,2,'omitnan');
        

        
%         spikeSum(:,:) = cellfun(@(x) sum(x>=h1.tmin & x<=h1.tmax),spikesMasked(:,logical(elapsedMask)));
        
%         % add trial reps if available
%         for elap = 1:(max(elapsedMask)-1)
%             spikeSum(:,:) = spikeSum(:,:) + cellfun(@(x) sum(x>=h1.tmin & x<=h1.tmax),spikesMasked(:,elapsedMask==elap+1,elap+1));
%         end
    end
    % tuning = mean(cellfun(@(x) sum(x>=h1.tmin & x<=h1.tmax),h1.spikedata),3)./(h1.tmax-h1.tmin);
    tuning(isnan(tuning)) = 0;

    for iplot = 1 : h.numplots
        % axes(h.axes{iplot});
        if ~isempty(tuning)
            h.lines{iplot}.YData = tuning(iplot,:);
            h.axes{iplot}.YLimMode = 'auto';
            h.axes{iplot}.YLim(1) = 0;
        else 
            
        end
    end
    fprintf("Overview | t = %f\n",toc*1e3);
catch err
    getReport(err)
    keyboard;
end

end