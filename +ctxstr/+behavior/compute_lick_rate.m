function lick_rate = compute_lick_rate(lick_times, t, lick_window)
% At each time point in t, compute the number of licks detected within the
% past 'lick_window' seconds.

num_timepoints = length(t);
lick_counts = zeros(1, num_timepoints);

for k = 1:num_timepoints
    licks = (lick_times > (t(k)-lick_window)) & (lick_times < t(k));
    lick_counts(k) = sum(licks);
end

lick_rate = lick_counts / lick_window;