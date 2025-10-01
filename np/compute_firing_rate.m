function fr = compute_firing_rate(spikes, t)
% Calculate the number of spikes that occured in each bin of t

spike_times = spikes(:,1);
num_spikes = length(spike_times);

[F, x] = ecdf(spike_times);
F = F * num_spikes;

% The first two entries of x from 'ecdf' is the time of the first spike,
% with corresponding counts (F) of 0 and 1. We can't have duplicate values
% in x for interp1
x(1) = 0;

T = t(2) - t(1);
y1 = interp1(x, F, t, 'previous', 'extrap');
y2 = interp1(x, F, t-T, 'previous', 'extrap');

fr = y1 - y2;