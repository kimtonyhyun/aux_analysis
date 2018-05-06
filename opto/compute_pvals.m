%% Compute p-values

num_cells = ds.num_classified_cells;

pvals = zeros(num_cells, 1);
effect_type = zeros(num_cells, 1); % 1 if inhibited, 2 if disinihibted
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
        [pvals(k), effect_type(k)] = min([p1, p2]); % Consider both inhibited and disinhibited cases
    end
end

% Sort by p-value
[sorted_pvals, sorted_inds] = sort(pvals);
stats = [sorted_pvals, sorted_inds, num_events(sorted_inds,:) effect_type(sorted_inds)];

%%

p_thresh = 0.05/num_cells;
is_significant = sorted_pvals < p_thresh;
num_significant = sum(is_significant);
stats_sig = stats(is_significant,:);

% Logical
inhibited_inds = (stats_sig(:,6)==1);
disinhibited_inds = (stats_sig(:,6)==2);

% Cell inds
inhibited_inds = stats_sig(inhibited_inds,2)';
num_inhibited = length(inhibited_inds);

disinhibited_inds = stats_sig(disinhibited_inds,2)';
num_disinhibited = length(disinhibited_inds);

other_inds = setdiff(1:num_cells, [inhibited_inds, disinhibited_inds]);

%%
save('optocells.mat', 'inhibited_inds', 'disinhibited_inds', 'other_inds', 'p_thresh');

%% Inhibited traces

dataset_name = dirname;
plot_opto_cell(ds, inhibited_inds, laser_inds.off, {laser_inds.real});
title(sprintf('%s: Inhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_inhibited, num_cells, 100*num_inhibited/num_cells));

%% Disinhibited traces

plot_opto_cell(ds, disinhibited_inds, laser_inds.off, {laser_inds.real});
title(sprintf('%s: Disinhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_disinhibited, num_cells, 100*num_disinhibited/num_cells));

%% Show as cell map

ds.plot_cell_map({inhibited_inds, 'c'; disinhibited_inds, 'r'; other_inds, 'w'});
title(sprintf('%s: Inhibited (%d, cyan); Disinhibited (%d, red); No effect (%d, white)',...
    dataset_name, num_inhibited, num_disinhibited, length(other_inds)));