%% Evaluate Ctx-Str correlations

clear all;

% Use only frames belonging to trials
ds_ctx = DaySummary('str.txt', 'ctx/union/resampled');
ds_str = DaySummary('str.txt', 'str/union/resampled');

us_times = ds_str.trial_indices(:,3);

% Compute correlations
corrlists = compute_ctxstr_corrlists(ds_ctx, ds_str);

%% Examine Ctx-Str correlations

browse_corrlist(corrlists.ctxstr, ds_ctx, ds_str, 'names', {'ctx', 'str'}, 'frames', us_times);

%%

browse_corrlist(corrlists.ctx, ds_ctx, ds_ctx, 'names', 'ctx', 'frames', us_times);

%%

browse_corrlist(corrlists.str, ds_str, ds_str, 'names', 'str', 'frames', us_times);