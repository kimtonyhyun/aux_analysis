%% Compute p-values

num_cells = ds.num_classified_cells;

pvals = zeros(num_cells, 1);
effect_type = cell(num_cells, 1);
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
        [pvals(k), type] = min([p1, p2]); % Consider both inhibited and disinhibited cases
        if type == 1
            effect_type{k} = 'inhibited';
        else
            effect_type{k} = 'disinhibited';
        end
    end
end

% Sort by p-value
[sorted_pvals, sorted_inds] = sort(pvals);

stats = struct('pval', num2cell(sorted_pvals),...
                'cell_idx', num2cell(sorted_inds),...
                'events_off', num2cell(num_events(sorted_inds,1)),...
                'events_real', num2cell(num_events(sorted_inds,2)),...
                'events_sham', num2cell(num_events(sorted_inds,3)),...
                'type', effect_type(sorted_inds));

%%

p_thresh = 0.05/num_cells;
is_significant = sorted_pvals < p_thresh;
num_significant = sum(is_significant);
stats_sig = stats(is_significant);

% Logical
inhibited_inds = strcmp({stats_sig.type}, 'inhibited');
disinhibited_inds = strcmp({stats_sig.type}, 'disinhibited');

% Cell inds
inhibited_inds = [stats_sig(inhibited_inds).cell_idx];
num_inhibited = length(inhibited_inds);

disinhibited_inds = [stats_sig(disinhibited_inds).cell_idx];
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