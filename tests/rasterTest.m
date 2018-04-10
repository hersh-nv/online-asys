% raster plot test
% APR 2018
% HN
%
% generates a fake array of trialdata

close all;

TOTAL_TRIALS = 10;
SAMPLING_FREQ = 2000;
TRIAL_LEN = 0.5;        % in sec
SPIKE_PROB = 0.01;
TOTAL_SAMPLES = SAMPLING_FREQ*TRIAL_LEN;

spikes_binary = zeros(TOTAL_TRIALS,TOTAL_SAMPLES);

for trialn = 1:TOTAL_TRIALS
    samplen = 1:(SAMPLING_FREQ*TRIAL_LEN);
    
    spikes_binary(trialn,samplen) = (rand([1,TOTAL_SAMPLES])<SPIKE_PROB);
    spikes_binary(trialn,samplen(samplen<=TOTAL_SAMPLES*0.75 & samplen>TOTAL_SAMPLES*0.25)) ...
        =(rand([1,TOTAL_SAMPLES/2])<(SPIKE_PROB*10));
%     spikes_binary(trialn,samplen<TOTAL_SAMPLES*0.25)=(rand<SPIKE_PROB);
end
%%
spikes_idx = zeros(TOTAL_TRIALS,1);

for trialn = 1:TOTAL_TRIALS
    spikeno = length(find(spikes_binary(trialn,:)));
    spikes_idx(trialn,spikeno)=0;
    spikes_idx(trialn,1:spikeno) = find(spikes_binary(trialn,:));
end


figure
subplot(3,1,1)
hold on
tic
for trialn = 1:TOTAL_TRIALS
%     hold on
%     plot(spikes_idx(trialn,:),-trialn,'k.');
    for spiken = 1:length(spikes_idx(trialn,:));
        if (spikes_idx(trialn,spiken))
            plot(spikes_idx(trialn,spiken).*[1 1]./SAMPLING_FREQ,-trialn+[-0.5 0.5],'k');
        end
    end
    ylim([-10.5 -0.5]);
end
t=toc; disp(t);

subplot(3,1,2)
tic
colormap(gray)
imagesc(~spikes_binary)
t=toc; disp(t);

subplot(3,1,3)
tic
spikes_binary_small = imresize(spikes_binary,[TOTAL_TRIALS,500],'bilinear');
imagesc(~spikes_binary_small)
t=toc; disp(t);