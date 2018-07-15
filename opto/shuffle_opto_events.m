function [p_lower, p_upper] = shuffle_opto_events(events_per_trial, laser_off_trials, laser_on_trials)
% Compute the p-value of observed opto effect, by performing random trial
% shuffles.

show_cdf = true;

true_on_events = sum(events_per_trial(laser_on_trials));

all_trials = union(laser_off_trials, laser_on_trials);
num_on = length(laser_on_trials);

num_shuffles = 1e3;
shuffled_on_events = zeros(1, num_shuffles);
for k = 1:num_shuffles
    shuffled_on_trials = randsample(all_trials, num_on);
    shuffled_on_events(k) = sum(events_per_trial(shuffled_on_trials));
end

% Fraction of shuffles with number of opto events as FEW as the one
% observed. Note that it is important to have the equality for this
% comparison. Consider the case where there are 0 events during laser on
% trials. Since it is impossible for the shuffled event counts to be less
% than 0, in the case that we applied a strict inequality, all such cells
% would automatically classified as opto-inhibited.
p_lower = sum(shuffled_on_events<=true_on_events)/num_shuffles;

% Fraction of shuffles with number of opto events as MANY as the one
% observed
p_upper = sum(shuffled_on_events>=true_on_events)/num_shuffles;

if (show_cdf)
    [F,x] = ecdf(shuffled_on_events);
    plot(x,F,'.-');
    xlabel('Number of LASER-ON events');
    ylabel('Cumulative fraction');
    grid on;
    hold on;
    plot(true_on_events*[1 1], [0 1], 'r--', 'LineWidth', 2);
    hold off;
    legend('Shuffle',...
           sprintf('Observed (p_L=%.4f, p_U=%.4f)',p_lower,p_upper),...
           'Location', 'SouthEast');
end