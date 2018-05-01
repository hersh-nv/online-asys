function rasterStart(hObject)

h = guidata(hObject)

if (~isempty(h.trialdata))    
    axes(h.rasterAxes)
    hold on
    for IDx = 1:h.totalID
%         try     delete(rPlotHand(IDx))    % very lazy and non-recommended way to clear existing plot if it exists
%         catch   % if doesn't exist, nothing to do
%         end

        if h.IDreps(IDx)                                                    % if there is at least one recorded trial for this IDtype...
            for spikex = 1:length(h.trialdata{h.selCh,IDx,h.IDreps(IDx)})   % get spikes from the most recent one (stored in h.IDreps)
                % make raster with IDtype on yaxis, and save handle in h.rPlotHand
                h.rPlotHand(IDx) = plot( ...
                    gca,double(h.trialdata{h.selCh,IDx,h.IDreps(IDx)}(spikex)).*[1 1]./h.sampling_freq, ...
                    -IDx+[-0.5 0.5], ...
                    'k');
            end
        end
    end
    xlim([h.tmin,h.tmax]);
    ylim([-h.totalID-0.5,-0.5]);
    
end
guidata(hObject,h);

end