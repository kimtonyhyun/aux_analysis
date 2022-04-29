% Compute correlations

C_ctx = ctxstr.analysis.corr.compute_corr_over_trials(ctx_traces_by_trial, ctx_traces_by_trial, st_trial_inds);
C_str = ctxstr.analysis.corr.compute_corr_over_trials(str_traces_by_trial, str_traces_by_trial, st_trial_inds);
C_ctxstr = ctxstr.analysis.corr.compute_corr_over_trials(ctx_traces_by_trial, str_traces_by_trial, st_trial_inds);

%% Visualization #1: Correlations

ctxstr.vis.show_correlations(C_ctx, C_str, C_ctxstr, dataset_name);