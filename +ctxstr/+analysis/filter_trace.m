function trace_filt = filter_trace(trace, cutoff_freq, fps)
% Compute a low-pass filtered version of the fluorescence trace.

[b,a] = butter(2, cutoff_freq/(fps/2));
trace_filt = filtfilt(b,a,trace);
