%% Compute p-values by trial shuffles
opto = load('opto.mat');

[stats_sig, info] = compute_pvals_by_shuffle(ds, opto,...
    'dataset_name', dirname,...
    'score_type', 'events',...
    'num_shuffles', 1e5);

shuffle_savename = sprintf('shuffle_%s.mat', datestr(now, 'yymmdd-HHMMSS'));
save(shuffle_savename, 'info', 'stats_sig');

%% Visualize shuffle stats
visualize_shuffle(info);

%% Inhibited traces
visualize_opto_traces(ds, info, 'inhibited');

%% Disinhibited traces
visualize_opto_traces(ds, info, 'disinhibited');

%% Show as cell map
visualize_opto_cellmap(ds, info);