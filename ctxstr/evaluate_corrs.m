% Trials only

clear all;

ds_ctx = DaySummary('str.txt', 'ctx/union/resampled');
ds_str = DaySummary('str.txt', 'str/union/resampled');

%% Full traces

clear all;

ds_ctx = DaySummary('', 'ctx/union/resampled');
ds_str = DaySummary('', 'str/union/resampled');

%% Compute correlations

corrlists = compute_ctxstr_corrlists(ds_ctx, ds_str);

%% Examine Ctx-Str correlations

show_ctxstr_corrs(corrlists.ctxstr, ds_ctx, ds_str);

%%

show_ctxstr_corrs(corrlists.ctx, ds_ctx, ds_ctx);

%%

show_ctxstr_corrs(corrlists.str, ds_str, ds_str);