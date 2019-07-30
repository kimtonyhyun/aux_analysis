%% Compute p-values by trial shuffles

opto = load('opto.mat');

[stats_sig, info] = compute_pvals_by_shuffle(ds, opto.trial_inds,...
    'dataset_name', dirname,...
    'score_type', 'fluorescence',...
    'num_shuffles', 1e5);

visualize_shuffle(info);

shuffle_savename = sprintf('shuffle_%s.mat', datestr(now, 'yymmdd-HHMMSS'));
save(shuffle_savename, 'info', 'stats_sig');

%% Unpack results
inhibited_inds = info.results.inds.inhibited;
disinhibited_inds = info.results.inds.disinhibited;
other_inds = info.results.inds.other;
num_inhibited = length(inhibited_inds);
num_disinhibited = length(disinhibited_inds);
num_cells = info.results.num_cells;

dataset_name = info.dataset_name;
laser_on_frames = opto.laser_inds.(info.settings.laser_on_type);

%% Inhibited traces

plot_opto_cell(ds, inhibited_inds, opto.laser_inds.off, laser_on_frames);
title(sprintf('%s: Inhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_inhibited, num_cells, 100*num_inhibited/num_cells));

%% Disinhibited traces

plot_opto_cell(ds, disinhibited_inds, opto.laser_inds.off, laser_on_frames);
title(sprintf('%s: Disinhibited cells (%d of %d; %.1f%%)',...
    dataset_name, num_disinhibited, num_cells, 100*num_disinhibited/num_cells));

%% Show as cell map

ds.plot_cell_map({inhibited_inds, 'c'; disinhibited_inds, 'r'; other_inds, 'w'});
title(sprintf('%s: Inhibited (%d, cyan); Disinhibited (%d, red); No effect (%d, white)',...
    dataset_name, num_inhibited, num_disinhibited, length(other_inds)));