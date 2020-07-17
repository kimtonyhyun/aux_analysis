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

browse_corrlist(corrlists.ctxstr, ds_ctx, ds_str, 'names', {'ctx', 'str'});

%%

browse_corrlist(corrlists.ctx, ds_ctx, ds_ctx, 'names', 'ctx');

%%

browse_corrlist(corrlists.str, ds_str, ds_str, 'names', 'str');