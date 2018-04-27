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
        num_events(k,1) = length(intersect(event_times, laser.off));
        num_events(k,2) = length(intersect(event_times, laser.real));
        num_events(k,3) = length(intersect(event_times, laser.sham));
        [p1, p2] = count_opto_events(event_times, laser.off, laser.real);
        pvals(k) = min([p1, p2]);
    end
end

% Sort by p-value
[sorted_pvals, sorted_inds] = sort(pvals);
stats = [sorted_pvals, sorted_inds, num_events(sorted_inds,:)];