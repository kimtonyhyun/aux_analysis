function plot_opto_cell(ds, cell_indices, laser_off, laser_on)
% Like 'plot_opto_trace' but uses DaySummary and cell index rather than the
% trace itself. The use of DS allows for additional visualization, e.g.
% events.

num_cells = length(cell_indices);
num_events_per_cell = zeros(num_cells,2); % [Laser-off Laser-on]

for j = 1:num_cells
    cell_idx = cell_indices(j);
    
    trace = ds.get_trace(cell_idx);
    m = min(trace);
    M = max(trace);
    trace = (trace-m)/(M-m); % Normalize to [0 1]
    
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
        
        num_events_per_cell(j,1) = length(laser_off_events);
        num_events_per_cell(j,2) = length(laser_on_events);
    end
end

% Formatting
if num_cells > 1
    grid off;
end
xticks([]);
xlabel(sprintf('Frame (%d total)', length(trace)));
% ylabel('Fluorescence (norm.)');
ylim([-0.5 num_cells+0.5]);
yticks(0:(num_cells-1));
cell_labels = cell(1, num_cells);
for k = 1:num_cells
    cell_labels{k} = sprintf('Cell %d (Evt off/on: %d/%d)',...
        cell_indices(k), num_events_per_cell(k,1), num_events_per_cell(k,2));
end
yticklabels(cell_labels);
hold off;