%% Evaluate Ctx-Str correlations

clear all;

dataset_name = dirname;
names = {sprintf('%s-ctx', dataset_name), sprintf('%s-str', dataset_name)};

% Use only frames belonging to trials
% Note that we use frame indices in 'str.txt'. This is because the cortex
% data is resampled at the frame clock of the striatum movie.
ds_ctx = DaySummary('str.txt', 'ctx/union/resampled');
ds_str = DaySummary('str.txt', 'str/union/resampled');

% Compute correlations
corrlists.ctxstr = compute_corrlist(ds_ctx, ds_str);
corrlists.ctx = compute_corrlist(ds_ctx);
corrlists.str = compute_corrlist(ds_str);

%% Examine Ctx-Str correlations

browse_corrlist(corrlists.ctxstr, ds_ctx, ds_str, 'names', names);

%%

browse_corrlist(corrlists.ctx, ds_ctx, ds_ctx, 'names', names{1});

%%

browse_corrlist(corrlists.str, ds_str, ds_str, 'names', names{2});