%% Compute p-values

num_cells = ds.num_classified_cells;

pvals = zeros(num_cells, 1);
num_events = zeros(num_cells, 3); % Laser status: [Off Real Sham]

for k = 1:num_cells
    events = ds.get_events_full(k);
    
    if isempty(events)
        pvals(k) = Inf;
    else
        event_times = events(:,2); % Note: using peak frames
        num_events(k,1) = length(intersect(event_times, laser_inds.off));
        num_events(k,2) = length(intersect(event_times, laser_inds.real));
        num_events(k,3) = length(intersect(event_times, laser_inds.sham));
        [p1, p2] = count_opto_events(event_times, laser_inds.off, laser_inds.real);
        pvals(k) = min([p1, p2]); % Consider both inhibited and disinhibited cases
    end
end

% Sort by p-value
[sorted_pvals, sorted_inds] = sort(pvals);
stats = [sorted_pvals, sorted_inds, num_events(sorted_inds,:)];

%% Display

plot_opto_cell(ds, stats(1:25,2), laser_inds.off, {laser_inds.real});
% plot_opto_cell(ds, stats(1:22,2), laser_inds.off, {laser_inds.real, laser_inds.sham});