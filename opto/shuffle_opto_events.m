function [p_lower, p_upper, info] = shuffle_opto_events(ds, cell_idx, laser_off_trials, laser_on_trials)
% Compute the p-value of observed opto effect, by performing random trial
% shuffles.

use_rate = true;
show_cdf = false;

% Collect event information from cell
num_trials = ds.num_trials;
events_per_trial = zeros(num_trials, 1);
for m = 1:num_trials
    eventdata = ds.trials(m).events{cell_idx};
    num_events = size(eventdata,1);
    if use_rate
        num_frames = diff(ds.trial_indices(m,[1 end])) + 1;
        events_per_trial(m) = num_events / num_frames;
    else
        events_per_trial(m) = num_events;
    end
end

true_on_events = mean(events_per_trial(laser_on_trials));

all_trials = union(laser_off_trials, laser_on_trials);
num_laser_on_trials = length(laser_on_trials);

num_shuffles = 1e4;
shuffled_on_events = zeros(1, num_shuffles);
for k = 1:num_shuffles
    shuffled_on_trials = randsample(all_trials, num_laser_on_trials);
    shuffled_on_events(k) = mean(events_per_trial(shuffled_on_trials));
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

% Additional info
info.use_rate = use_rate;
info.true_events.off = mean(events_per_trial(laser_off_trials));
info.true_events.on = true_on_events;

info.shuffle_distr.num_shuffles = num_shuffles;
percentiles_x = [5 25 50 75 95];
info.shuffle_distr.x = percentiles_x;
info.shuffle_distr.y = prctile(shuffled_on_events, percentiles_x);

% Optional visualization
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