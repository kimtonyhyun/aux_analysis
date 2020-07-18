%% Evaluate Ctx-Str correlations

clear all;

dataset_name = dirname;
names = {sprintf('%s-ctx', dataset_name), sprintf('%s-str', dataset_name)};

meta = load('ctxstr.mat');
us_times = find(meta.str.us);

% Use all frames irrespective of trial structure
ds_ctx = DaySummary('', 'ctx/union/resampled');
ds_str = DaySummary('', 'str/union/resampled');

% Compute correlations
corrlists = compute_ctxstr_corrlists(ds_ctx, ds_str);

%% Examine Ctx-Str correlations

browse_corrlist(corrlists.ctxstr, ds_ctx, ds_str, 'names', names, 'frames', us_times);

%%

browse_corrlist(corrlists.ctx, ds_ctx, ds_ctx, 'names', names{1}, 'frames', us_times);

%%

browse_corrlist(corrlists.str, ds_str, ds_str, 'names', names{2}, 'frames', us_times);