%% Compute p-values

num_cells = ds.num_classified_cells;

pvals = zeros(num_cells, 1);
num_events = zeros(num_cells, 1);

for k = 1:num_cells
    events = ds.get_events_full(k);
    num_events(k) = size(events,1);
    
    [p1, p2] = count_opto_events(events(:,2), laser_on, laser_off);
    pvals(k) = min([p1, p2]);
end

%% Sort by p-value

[sorted_pvals, sorted_inds] = sort(pvals);
stats = [sorted_pvals, sorted_inds, num_events(sorted_inds)];