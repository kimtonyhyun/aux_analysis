% To be used after running 'ctxstr.ephys.show_results', which produces:
%   - t_im: Imaging time, believed to be incorrect
%   - cascade_trace
%   - ground_truth_spike_prob

% First, show CASCADE-inferred and ground truth spike probs in the original
% time provided
ax1 = subplot(3,1,1);
yyaxis left;
plot(t_im, cascade_trace, 'k.-');
xlabel('ORIGINAL Time (s)');
ax1.YAxis(1).Color = 'k';
ylabel('CASCADE');
yyaxis right;
plot(t_im, ground_truth_spike_prob, 'm.-');
ax1.YAxis(2).Color = 'm';
ylabel('Ground truth');
title(title_str, 'Interpreter', 'none');

% Next, compute temporally offset versions of the CASCADE trace.
%
% Positive offset means that the CASCADE trace is pushed "to the right".
% Conceptually, the time axis for the CASCADE trace should be shared with
% that of the DFF trace.
time_offsets = 0:0.01:0.15;
num_offsets = length(time_offsets);
corr_vals = zeros(size(time_offsets));

for k = 1:num_offsets
    t_im_offset = t_im + time_offsets(k);

    % Resample the shifted CASCADE trace at the time corresponding to the
    % samples in ground_truth_spike_prob
    cascade_trace2 = interp1(t_im_offset, cascade_trace, t_im, 'linear')';
    not_nan = ~isnan(cascade_trace2);
    corr_vals(k) = corr(cascade_trace2(not_nan), ground_truth_spike_prob(not_nan));
end

% Fit quadratic to corr_vals, and compute optimal offset
p = polyfit(time_offsets, corr_vals, 2);
time_offsets_cont = linspace(time_offsets(1), time_offsets(end), 1e3);
corr_vals_cont = polyval(p, time_offsets_cont);

best_offset = -p(2)/(2*p(1));
best_corr_val = polyval(p, best_offset);

subplot(3,1,2);
plot(time_offsets, corr_vals, 'b.', 'MarkerSize', 12);
hold on;
plot(time_offsets_cont, corr_vals_cont, 'b');
plot(best_offset, best_corr_val, 'r.', 'MarkerSize', 18);
hold off;
legend('Data', 'Fit', sprintf('Optimum shift = %.3f s', best_offset),...
    'Location', 'SouthEast');
xlabel('Rightward shift of CASCADE trace (s)');
ylabel('CASCADE-GT correlation');

ax3 = subplot(3,1,3);
yyaxis left;
plot(t_im + best_offset, cascade_trace, 'k.-');
xlabel('CORRECTED Time (s)');
ax1.YAxis(1).Color = 'k';
ylabel('CASCADE');
yyaxis right;
plot(t_im, ground_truth_spike_prob, 'm.-');
ax1.YAxis(2).Color = 'm';
ylabel('Ground truth');

linkaxes([ax1 ax3], 'x');
xlim([7 13]);