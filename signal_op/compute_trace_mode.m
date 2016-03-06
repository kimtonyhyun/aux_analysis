function [fitted_mode, empirical_mode] = compute_trace_mode(trace)

num_frames = length(trace);

% Compute mode based on empirical histogram
num_bins = max(50, num_frames/50);
[n, bin_centers] = hist(trace, num_bins);
[~, max_idx] = max(n);
empirical_mode = bin_centers(max_idx);

% Fit for mode
half_width = max(10, floor(num_bins/20));
fit_idx_lower = max(1, max_idx-half_width);
fit_idx_upper = min(max_idx+half_width, num_bins);
fit_indices = fit_idx_lower:fit_idx_upper;

x = bin_centers(fit_indices);
y = n(fit_indices);
[p, ~, pmu] = polyfit(x, y, 2); % Quadratic fit, with polyfit centering

% Fitted mode
a = p(1)/pmu(2)^2;
b = -2*pmu(1)*p(1)/pmu(2)^2 + p(2)/pmu(2);
fitted_mode = -b/(2*a);