function plot_opto_cell(ds, cell_indices, laser_off, laser_on)
% Like 'plot_opto_trace' but uses DaySummary and cell index rather than the
% trace itself. The use of DS allows for additional visualization, e.g.
% events.

if ~iscell(laser_on) % Allow for "multiple" lasers
    laser_on = {laser_on};
end

laser_colors = 'rmg';
num_lasers = length(laser_on);

cell_indices = flip(cell_indices); % Minor convenience

num_cells = length(cell_indices);
num_events_per_cell = zeros(num_cells,1+num_lasers); % [Laser-off Laser-on]

for j = 1:num_cells
    cell_idx = cell_indices(j);
    
    trace = ds.get_trace(cell_idx, 'norm');
    
    trace_offset = j-1;
    plot_opto_trace(trace+trace_offset, laser_off, laser_on);
    hold on;
    
    if ds.is_eventdata_loaded
        events = ds.get_events_full(cell_idx);
        event_times = events(:,2); % Note: using peak frames

        y_offset = trace_offset + 0.08;
        
        laser_off_events = intersect(event_times, laser_off);
        plot(laser_off_events, trace(laser_off_events) + y_offset, 'k.');
        num_events_per_cell(j,1) = length(laser_off_events);
        
        for l = 1:num_lasers
            laser_on_events = intersect(event_times, laser_on{l});
            plot(laser_on_events, trace(laser_on_events) + y_offset,...
                 '.', 'Color', laser_colors(l));      
            num_events_per_cell(j,1+l) = length(laser_on_events);
        end
    end
end

% Formatting
if num_cells > 1
    grid off;
end
xticks([]);
xlabel(sprintf('Frame (%d total)', length(trace)));
y_range = [-0.5 num_cells+0.5];
ylim(y_range);
yticks(0:(num_cells-1));
cell_labels = cell(1, num_cells);
for k = 1:num_cells
    event_str = sprintf('%d/', num_events_per_cell(k,:));
    cell_labels{k} = sprintf('Cell %d (Evts: %s)',...
        cell_indices(k), event_str(1:end-1));
end
yticklabels(cell_labels);

num_trials = ds.num_trials;
if num_trials > 1
    for j = 2:num_trials-1
        plot(ds.trial_indices(j,1)*[1 1], y_range, 'Color', 0.75*[1 1 1]);
    end
end
hold off;