function plot_opto_cell(ds, cell_indices, laser_off, laser_on)
% Like 'plot_opto_trace' but uses DaySummary and cell index rather than the
% trace itself. The use of DS allows for additional visualization, e.g.
% events.

num_cells = length(cell_indices);
for j = 1:num_cells
    cell_idx = cell_indices(j);
    
    trace = ds.get_trace(cell_idx);
    m = min(trace);
    M = max(trace);
    trace = (trace-m)/(M-m); % Normalize to [0 1]
    
    hold on;
    trace_offset = j-1;
    plot_opto_trace(trace+trace_offset, laser_off, laser_on);

    if ds.is_eventdata_loaded
        events = ds.get_events_full(cell_idx);
        event_times = events(:,2); % Note: using peak frames

        laser_off_events = intersect(laser_off, event_times);
        laser_on_events = intersect(laser_on, event_times);

        hold on;
        y_offset = trace_offset + 0.05;
        plot(laser_off_events, trace(laser_off_events) + y_offset, 'k*');
        plot(laser_on_events, trace(laser_on_events) + y_offset, 'r*');
        
        if (num_cells == 1)
            % Provide extra diagnostics if only one cell is plotted
            num_laser_off_events = length(laser_off_events);
            num_laser_on_events = length(laser_on_events);
            title(sprintf('Cell %d events: %d (laser OFF) vs. %d (laser ON)',...
                cell_idx, num_laser_off_events, num_laser_on_events));
        end
    end
end
xlabel('Frame');
ylabel('Fluorescence (norm.)');
ylim([0 num_cells]);
hold off;