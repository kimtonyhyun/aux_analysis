function [C_ctx, C_str, C_ctxstr] = compute_correlations(ctx_traces_by_trial, str_traces_by_trial)

% Conversion to double needed for cell2mat concatenation, if working with 
% Ca2+ traces which are stored as single
ctx_traces_by_trial = cellfun(@double, ctx_traces_by_trial, 'UniformOutput', 0);
str_traces_by_trial = cellfun(@double, str_traces_by_trial, 'UniformOutput', 0);

cont_ctx_traces = cell2mat(ctx_traces_by_trial); % [cells x time]
cont_str_traces = cell2mat(str_traces_by_trial);

% Pearson correlations
C_ctx = corr(cont_ctx_traces');
C_str = corr(cont_str_traces');
C_ctxstr = corr(cont_ctx_traces', cont_str_traces');

% ctxstr.vis.show_correlations(C_ctx, C_str, C_ctxstr, dataset_name);
