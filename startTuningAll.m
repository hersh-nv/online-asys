function h = startTuningAll(h)
% startTuningAll(handles) initialises the tuning curves in the
% GUI_Online_PlotAll figure. handles is a struct that contains all the
% handles and userdata for this GUI.
%
% HN May 2018
%
% See also GUI_ONLINE_PLOTALL, GUIDATA

h.numplots = 32; % hardcoded just for now

yplots = floor(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);

figure(h.figure1);      % draw into figure_plotAll
h.axes{1,h.numplots}=[];
h.stimTypesTotal=12;
for iplot=1:h.numplots
    % create and save handles to axes and lineplot separately
    h.axes{iplot} = subplot(yplots,xplots,iplot);
    h.lines{iplot} = plot(1:h.stimTypesTotal,zeros(1,h.stimTypesTotal));
    
    % adjust axes appearance
    h.axes{iplot}.XLim = [1 h.stimTypesTotal];
    h.axes{iplot}.YLimMode = 'auto';
    h.axes{iplot}.YLim(1) = 0;
    h.axes{iplot}.XTick=[];
    h.axes{iplot}.YTick=[];
end

% create plot update timer
h1 = guidata(h.figure_master);
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

% fetch master handles, where spikedata is stored
h1 = guidata(h.figure_master);

try 
    tuning = mean(cellfun(@(x) sum(x>=h1.tmin & x<=h1.tmax),h1.spikedata),3)./(h1.tmax-h1.tmin);
    tuning(isnan(tuning)) = 0; %

    for iplot = 1 : h.numplots
        % axes(h.axes{iplot});
        if ~isempty(tuning)
            h.lines{iplot}.YData = tuning(iplot,:);
            h.axes{iplot}.YLimMode = 'auto';
            h.axes{iplot}.YLim(1) = 0;
        else 
            
        end
    end
catch ME
    getReport(ME)
    keyboard;
end

end