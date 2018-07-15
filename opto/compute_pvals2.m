%% Compute p-values by trial shuffles

load('opto.mat');

laser_off_trials = trial_inds.off;
laser_on_trials = trial_inds.real;

%%
num_cells = ds.num_classified_cells;
num_trials = ds.num_trials;

p_thresh = 0.05/(num_cells*2); % The 2 is for two-sided correction
pvals = zeros(num_cells, 1);

effect_type = categorical(repmat({'-'}, num_cells, 1),...
    {'-', 'inhibited', 'disinhibited'});
num_events = zeros(num_cells, 2); % [Laser-off Laser-on]

for k = 1:num_cells
    % Collect event information from cell
    events_per_trial = zeros(num_trials, 1);
    for m = 1:num_trials
        eventdata = ds.trials(m).events{k};
        events_per_trial(m) = size(eventdata,1);
    end
    
    % Tabulate for later inspection
    num_events(k,1) = sum(events_per_trial(laser_off_trials));
    num_events(k,2) = sum(events_per_trial(laser_on_trials));
    
    % Perform shuffle test
    [p1, p2] = shuffle_opto_events(events_per_trial, laser_off_trials, laser_on_trials);
    title(sprintf('Cell %d', k));
    drawnow;
    pause;
    
    [pvals(k), type] = min([p1, p2]);
    
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

%% Inhibited traces

dataset_name = dirname;
plot_opto_cell(ds, inhibited_inds, laser_inds.off, {laser_inds.real, laser_inds.sham});
title(sprintf('%s: Inhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_inhibited, num_cells, 100*num_inhibited/num_cells));

%% Disinhibited traces

dataset_name = dirname;
plot_opto_cell(ds, disinhibited_inds, laser_inds.off, {laser_inds.real, laser_inds.sham});
title(sprintf('%s: Disinhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_disinhibited, num_cells, 100*num_disinhibited/num_cells));

%% Show as cell map

ds.plot_cell_map({inhibited_inds, 'c'; disinhibited_inds, 'r'; other_inds, 'w'});
title(sprintf('%s: Inhibited (%d, cyan); Disinhibited (%d, red); No effect (%d, white)',...
    dataset_name, num_inhibited, num_disinhibited, length(other_inds)));