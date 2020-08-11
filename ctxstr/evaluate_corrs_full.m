%% Evaluate Ctx-Str correlations

clear all;

dataset_name = dirname;
names = {sprintf('%s-ctx', dataset_name), sprintf('%s-str', dataset_name)};

meta = load('ctxstr.mat');
us_times = find(meta.str.us);

% Use all frames irrespective of trial structure
ds_path = 'cnmf1/resampled';
ds_ctx = DaySummary('', fullfile('ctx', ds_path));
ds_str = DaySummary('', fullfile('str', ds_path));

%% Compute correlations

corrlists.ctxstr = compute_corrlist(ds_ctx, ds_str);
corrlists.ctx = compute_corrlist(ds_ctx);
corrlists.str = compute_corrlist(ds_str);

%% Examine Ctx-Str correlations

browse_corrlist(corrlists.ctxstr, ds_ctx, ds_str, 'names', names, 'frames', us_times);

%%

browse_corrlist(corrlists.ctx, ds_ctx, ds_ctx, 'names', names{1}, 'frames', us_times);

%%

browse_corrlist(corrlists.str, ds_str, ds_str, 'names', names{2}, 'frames', us_times);