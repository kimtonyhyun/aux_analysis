%% Compute p-values by trial shuffles
opto = load('opto.mat');

scoring_methods = {'fluorescence', 'event_count', 'event_amp_sum'};

for k = 1:length(scoring_methods)
    scoring_method = scoring_methods{k};
    [stats_sig, info] = compute_pvals_by_shuffle(ds, opto,...
        'dataset_name', dirname,...
        'score_type', scoring_method,...
        'num_shuffles', 1e5);

    shuffle_savename = sprintf('shuffle_%s_%s.mat', scoring_method, datestr(now, 'yymmdd-HHMMSS'));
    save(shuffle_savename, 'info', 'stats_sig');
end

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