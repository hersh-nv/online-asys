function rasterUpdate(timer,event,hObject)
 
h = guidata(hObject);

if isempty(h.plottedTrialNo)
    h.plottedTrialNo = zeros(h.maxCh,1);
end

if (~isempty(h.trialdata))    
    axes(h.rasterAxes)
    hold on
    for IDx = 1:h.totalID
        if h.IDreps(IDx) > h.plottedTrialNo(IDx) % if a newer trial than one currently plotted has occured
        
            if (h.plottedTrialNo(IDx)>0)
                delete(h.rPlotHand(IDx,:));
                fprintf('Stim ID %i: erased\n',IDx);
            end
            
            for spikex = 1:length(h.trialdata{h.selCh,IDx,h.IDreps(IDx)})   % get spikes from the most recent one (stored in h.IDreps)
                % make raster with IDtype on yaxis, and save handle in h.rPlotHand
                h.rPlotHand(IDx,spikex) = plot( ...
                    gca,double(h.trialdata{h.selCh,IDx,h.IDreps(IDx)}(spikex)).*[1 1]./h.sampling_freq, ...
                    -IDx+[-0.5 0.5], ...
                    'k');
            end
            
            h.plottedTrialNo(IDx) = h.plottedTrialNo(IDx)+1;
            fprintf('Stim ID %i: plotted\n',IDx);
        end
    end
    xlim([h.tmin,h.tmax]);
    ylim([-h.totalID-0.5,-0.5]);
    
end
guidata(hObject,h);

end