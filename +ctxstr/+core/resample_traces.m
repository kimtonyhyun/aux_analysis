function resampled_data = resample_traces(data, t)

% Note: interp1 works on columns
resampled_data.traces = interp1(data.t, data.traces', t, 'linear')';
resampled_data.t = t;