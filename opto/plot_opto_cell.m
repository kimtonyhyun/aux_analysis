function plot_opto_cell(ds, cell_idx, laser_off, laser_on)
% Like 'plot_opto_trace' but uses DaySummary and cell index rather than the
% trace itself. The use of DS allows for additional visualization, e.g.
% events.

trace = ds.get_trace(cell_idx);
plot_opto_trace(trace, laser_off, laser_on);
xlabel('Frame');
ylabel('Fluorescence');
title(sprintf('Cell %d', cell_idx));

if ds.is_eventdata_loaded
    events = ds.get_events_full(cell_idx);
    event_times = events(:,2); % Note: using peak frames
    
    laser_off_events = intersect(laser_off, event_times);
    laser_on_events = intersect(laser_on, event_times);
    
    hold on;
    y_offset = 0.05 * diff(get(gca, 'YLim'));
    plot(laser_off_events, trace(laser_off_events) + y_offset, 'k*');
    plot(laser_on_events, trace(laser_on_events) + y_offset, 'r*');
    hold off;
    
    num_laser_off_events = length(laser_off_events);
    num_laser_on_events = length(laser_on_events);
    title(sprintf('Cell %d event counts: %d (laser OFF) vs. %d (laser ON)',...
        cell_idx, num_laser_off_events, num_laser_on_events));
end