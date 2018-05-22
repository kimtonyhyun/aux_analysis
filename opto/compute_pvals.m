%% Compute p-values

num_cells = ds.num_classified_cells;

p_thresh = 0.05/num_cells;
pvals = zeros(num_cells, 1);

effect_type = categorical(repmat({'-'}, num_cells, 1),...
    {'-', 'inhibited', 'disinhibited'});
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
        fprintf('Cell %d\n', k);
        [p1, p2] = count_opto_events(event_times, laser_inds.off, laser_inds.real);
        [pvals(k), type] = min([p1, p2]); % Consider both inhibited and disinhibited cases
    end
    
    if (pvals(k) < p_thresh)
        if type == 1
            effect_type(k) = 'inhibited';
        elseif type == 2
            effect_type(k) = 'disinhibited';
        end
    end
end

% Sort by p-value
[sorted_pvals, sorted_inds] = sort(pvals);

stats = table(sorted_pvals, sorted_inds, num_events(sorted_inds,:), effect_type(sorted_inds),...
    'VariableNames', {'pval', 'cell_idx', 'num_events', 'effect'});

%%

is_significant = sorted_pvals < p_thresh;
num_significant = sum(is_significant);
stats_sig = stats(is_significant,:);

% Logical
inhibited_inds = (stats_sig.effect == 'inhibited');
disinhibited_inds = (stats_sig.effect == 'disinhibited');

% Cell inds
inhibited_inds = table2array(stats_sig(inhibited_inds, 'cell_idx'))';
num_inhibited = length(inhibited_inds);

disinhibited_inds = table2array(stats_sig(disinhibited_inds, 'cell_idx'))';
num_disinhibited = length(disinhibited_inds);

other_inds = setdiff(1:num_cells, [inhibited_inds, disinhibited_inds]);

%%
save('optocells.mat', 'inhibited_inds', 'disinhibited_inds', 'other_inds', 'p_thresh');

%% Inhibited traces

dataset_name = dirname;
plot_opto_cell(ds, inhibited_inds, laser_inds.off, {laser_inds.real, laser_inds.sham});
title(sprintf('%s: Inhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_inhibited, num_cells, 100*num_inhibited/num_cells));

%% Disinhibited traces

plot_opto_cell(ds, disinhibited_inds, laser_inds.off, {laser_inds.real, laser_inds.sham});
title(sprintf('%s: Disinhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_disinhibited, num_cells, 100*num_disinhibited/num_cells));

%% Show as cell map

ds.plot_cell_map({inhibited_inds, 'c'; disinhibited_inds, 'r'; other_inds, 'w'});
title(sprintf('%s: Inhibited (%d, cyan); Disinhibited (%d, red); No effect (%d, white)',...
    dataset_name, num_inhibited, num_disinhibited, length(other_inds)));