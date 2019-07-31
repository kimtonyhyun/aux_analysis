%% Compute p-values by trial shuffles
opto = load('opto.mat');

[stats_sig, info] = compute_pvals_by_shuffle(ds, opto,...
    'dataset_name', dirname,...
    'score_type', 'event_amp_sum',...
    'num_shuffles', 1e5);

shuffle_savename = sprintf('shuffle_%s.mat', datestr(now, 'yymmdd-HHMMSS'));
save(shuffle_savename, 'info', 'stats_sig');

%% Visualize shuffle stats
figure;
visualize_shuffle(info);

%% Inhibited traces
figure;
visualize_opto_traces(ds, info, 'inhibited');

%% Disinhibited traces
figure;
visualize_opto_traces(ds, info, 'disinhibited');

%% Show as cell map
figure;
visualize_opto_cellmap(ds, info);