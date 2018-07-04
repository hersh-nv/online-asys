function h = initializeInputParams(h)

h.minCh = 1;        % lowest channel number
h.maxCh = 32;       % highest channel number
h.selCh = h.minCh;

h.minChO = h.minCh; % lowest channel number (for Overview display only)
h.maxChO = h.maxCh; % highest channel number (for Overview display only)

h.tmin  = 0;        % lower bound on plotted time window (default)
h.tmax  = 1;        % upper bound on plotted time window (default)

h.pullUpdatePeriod = 0.25;     % how often to pull spike data     

% h.nRep  = 20;  % maximum number of stimuli repetitions for each type
h.sampling_freq = 30000;    % sampling rate for conversion of spiketimes to sec

% initialise data structures and arrays
h.IDreps = [];             % num of recorded reps per IDtype
h.plottedTrialNo = [];      
h.spikebuffer{h.maxCh,1}=[];
h.cmtbuffer = [];
h.cmttimesbuffer = [];
h.spikedata={};

h.focusSettings.singletonCheck = 0;
h.focusSettings.psthBinSize = 5;

% initialise figure handles
h.figure_overview = {};
h.figure_focus = {};
h.figure_focusMat = [];

end