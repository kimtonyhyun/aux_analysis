% Compute Pearson correlations over stereotypical trials
ctx_traces_st = ctxstr.core.concatenate_trials(ctx_traces_by_trial, st_trial_inds); % [cells x time]
str_traces_st = ctxstr.core.concatenate_trials(str_traces_by_trial, st_trial_inds);

C_ctx = corr(ctx_traces_st'); % corr works column-wise
C_str = corr(str_traces_st');
C_ctxstr = corr(ctx_traces_st', str_traces_st');

%% Visualization #1: Correlations

ctxstr.vis.show_correlations(C_ctx, C_str, C_ctxstr, dataset_name);