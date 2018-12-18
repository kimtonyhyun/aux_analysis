%% Compute p-values by trial shuffles

load('opto.mat');

laser_off_trials = trial_inds.off;
laser_on_type = 'real_postline';

laser_on_trials = getfield(trial_inds, laser_on_type);
laser_on_frames = getfield(laser_inds, laser_on_type);

%%
num_cells = ds.num_classified_cells;
num_trials = ds.num_trials;

p_thresh = 0.01/2; % The 2 is for two-sided correction
pvals = zeros(num_cells, 1);

effect_type = categorical(repmat({'-'}, num_cells, 1),...
    {'-', 'inhibited', 'disinhibited'});
mean_fluorescence = zeros(num_cells, 2); % [Laser-off Laser-on]
distrs = zeros(num_cells, 3); % [5th-percentile median 95-th percentile]

for k = 1:num_cells
    fprintf('%s: Cell %d...\n', datestr(now), k);
    
    % Perform shuffle test
    [p1, p2, info] = shuffle_opto_fluorescence(ds, k, laser_off_trials, laser_on_trials);
    mean_fluorescence(k,1) = info.true_fluorescence.off;
    mean_fluorescence(k,2) = info.true_fluorescence.on;
    distrs(k,:) = info.shuffle_distr.y([1 3 5]);
    
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

stats = table(sorted_pvals, sorted_inds, mean_fluorescence(sorted_inds,:),...
    distrs(sorted_inds,:), effect_type(sorted_inds),...
    'VariableNames', {'pval', 'cell_idx', 'fluorescence', 'shuffle_distr', 'effect'});

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

%% Sort cells by median shuffle event count, for visualization

[~, sorted_inds] = sort(distrs(:,2));
figure;
hold on;
for k = 1:num_cells
    cell_idx = sorted_inds(k);
    plot(k*[1 1], distrs(cell_idx,[1 end]), 'k-');
    plot(k, distrs(cell_idx,2), 'k.');
    switch effect_type(cell_idx)
        case '-'
            true_color = 'k';
        case 'inhibited'
            true_color = 'b';
        case 'disinhibited'
            true_color = 'r';
    end
    plot(k, mean_fluorescence(cell_idx,2), 'x', 'Color', true_color);
end
hold off;
xlim([0 num_cells+1]);
xlabel(sprintf('Sorted cells (%d total)', num_cells));
ylabel('Mean fluorescence over trial');
grid on;
legend('Shuffle distribution (5th-95th)', 'Shuffle median', 'Unshuffled (true) measurement',...
       'Location', 'NorthWest');
title(sprintf('%s: Inhibited (%d; blue), Disinhibited (%d; red)',...
    dirname, num_inhibited, num_disinhibited));

%% Inhibited traces

dataset_name = dirname;
plot_opto_cell(ds, inhibited_inds, laser_inds.off, laser_on_frames);
title(sprintf('%s: Inhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_inhibited, num_cells, 100*num_inhibited/num_cells));

%% Disinhibited traces

dataset_name = dirname;
plot_opto_cell(ds, disinhibited_inds, laser_inds.off, laser_on_frames);
title(sprintf('%s: Disinhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_disinhibited, num_cells, 100*num_disinhibited/num_cells));

%% Show as cell map

ds.plot_cell_map({inhibited_inds, 'c'; disinhibited_inds, 'r'; other_inds, 'w'});
title(sprintf('%s: Inhibited (%d, cyan); Disinhibited (%d, red); No effect (%d, white)',...
    dataset_name, num_inhibited, num_disinhibited, length(other_inds)));