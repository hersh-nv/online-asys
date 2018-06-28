function openFocusWindow(varargin)
% fig = openFocusWindow(ch) opens a Focus window with plots of the data
% contained in a single channel. There is no limit to the number of
% different Focus windows that can be open at a given time, but naturally a
% large number will put more strain on computer resources.

ch = varargin{3};
f_master = varargin{4};
h = struct;
h.figure_master = f_master;
h1 = guidata(f_master);

fprintf('Focusing on Channel %g!\n',ch);

f = figure(ch+2);
h.figure1 = f;

% psth
titlestr = sprintf('Channel %g',ch);
title(titlestr);

param1 = h1.param1Select.Value;

h.numplots = h1.nStim(param1);
yplots = round(sqrt(h.numplots/2)); % approx twice as many x plots as y plots
xplots = ceil(h.numplots/yplots);

h.spiketrain{h.numplots} = [];


%elapsedNum = h1.stimElapsed(h1.thisStim);
%spikesMasked = h1.spikedata(:,mask,:);

for iplot = 1:h.numplots
    subplot(yplots,xplots,iplot);
        
    mask = h1.stimIdxs(:,param1) == iplot;
    h.spiketrain{iplot} = sort([h1.spikedata{ch,mask,:}]);
    
    binSize = 0.01; % (s)
    h.hists{iplot} = histogram(h.spiketrain{iplot},0:binSize:1); % custom time window later
    h.hists{iplot}.BinCounts = h.hists{iplot}.BinCounts./sum(h1.stimElapsed(mask));
end

guidata(f,h);

end

function updateFocusWindow(f)
% fetch app data
h = guidata(f);
h1 = guidata(h.figure_master);

% interpret current stim
n = h1.thisIdxs(param1);
mask = h1.stimIdxs(:,param1) == iplot;

% fetch iteration count and spikes of current trial
elapsedNum = h1.stimElapsed(h1.thisStim);
thisSpikes = h1.spikedata{ch,h1.thisStim,elapsedNum};

% append new spiketimes to spike train; sort
h.spiketrain{n} = sort([h.spiketrain{n},h1.spikedata{ch,h1.thisStim,:}]);

% update hist
h.hists{n} = histogram(h.spiketrain{n},0:binSize:1); % custom time window later
h.hists{n}.BinCounts = h.hists{n}.BinCounts./sum(h1.stimElapsed(mask));
end