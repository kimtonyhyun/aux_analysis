% Compute Pearson correlations over stereotypical trials
cont_ctx_traces = ctxstr.core.concatenate_trials(ctx_traces_by_trial, st_trial_inds); % [cells x time]
cont_str_traces = ctxstr.core.concatenate_trials(str_traces_by_trial, st_trial_inds);

C_ctx = corr(cont_ctx_traces'); % corr works column-wise
C_str = corr(cont_str_traces');
C_ctxstr = corr(cont_ctx_traces', cont_str_traces');

%% Visualization #1: Correlations

ctxstr.vis.show_correlations(C_ctx, C_str, C_ctxstr, dataset_name);