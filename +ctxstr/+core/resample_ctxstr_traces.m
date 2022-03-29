function [resampled_ctx_traces, resampled_str_traces, t_common] = resample_ctxstr_traces(ctx_traces, t_ctx, str_traces, t_str)
% Note: All 'traces' variables have the shape: [cells x time]

% Compute the range of time common to both recordings
t_lims = [max([t_ctx(1) t_str(1)]) min([t_ctx(end) t_str(end)])];

num_samples = ceil(diff(t_lims) * 15); % At least 15 samples per s
t_common = linspace(t_lims(1), t_lims(2), num_samples);

% Note: interp1 works on columns
resampled_ctx_traces = interp1(t_ctx, ctx_traces', t_common, 'linear')';
resampled_str_traces = interp1(t_str, str_traces', t_common, 'linear')';