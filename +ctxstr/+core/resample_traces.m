function resampled_traces = resample_traces(traces, t, new_t)

% Note: interp1 works on columns
resampled_traces = interp1(t, traces', new_t, 'linear')';