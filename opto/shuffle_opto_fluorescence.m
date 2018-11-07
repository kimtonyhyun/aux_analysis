function [p_lower, p_upper, info] = shuffle_opto_fluorescence(ds, cell_idx, laser_off_trials, laser_on_trials)
% Compute the p-value of observed opto effect, by performing random trial
% shuffles.

num_shuffles = 1e4;
use_all_trials = false; % Sample from both laser_off and laser_on trials?
show_cdf = false;

% Collect event information from cell
%------------------------------------------------------------
num_trials = ds.num_trials;
fluorescence_per_trial = zeros(num_trials, 1);
full_trace = ds.get_trace(cell_idx);
for m = 1:num_trials
    trial_inds = ds.trial_indices(m,:); % [Start CS US End]
    % Sample the trace from 0.5 s (assuming 30 Hz) prior to CS onset until
    % the end of the trial.
    tr = full_trace(trial_inds(2)-15:trial_inds(4));
    fluorescence_per_trial(m) = mean(tr);
end

true_on_fl = mean(fluorescence_per_trial(laser_on_trials));

% Next, we will form subsamples of trials. The number of trials in the
% subsample equals the number of true opto trials.
%------------------------------------------------------------
if use_all_trials
    trials_to_sample_from = union(laser_off_trials, laser_on_trials);
else
    trials_to_sample_from = laser_off_trials;
end

num_laser_on_trials = length(laser_on_trials);

shuffled_fl = zeros(1, num_shuffles);
for k = 1:num_shuffles
    trial_shuffle = randsample(trials_to_sample_from, num_laser_on_trials);
    shuffled_fl(k) = mean(fluorescence_per_trial(trial_shuffle));
end

% Fraction of shuffles with number of opto events as FEW as the one
% observed. Note that it is important to have the equality for this
% comparison. Consider the case where there are 0 events during laser on
% trials. Since it is impossible for the shuffled event counts to be less
% than 0, in the case that we applied a strict inequality, all such cells
% would automatically classified as opto-inhibited.
p_lower = sum(shuffled_fl<=true_on_fl)/num_shuffles;

% Fraction of shuffles with number of opto events as MANY as the one
% observed
p_upper = sum(shuffled_fl>=true_on_fl)/num_shuffles;

% Additional info
%------------------------------------------------------------
info.use_all_trials = use_all_trials;
info.true_fluorescence.all = fluorescence_per_trial;
info.true_fluorescence.off = mean(fluorescence_per_trial(laser_off_trials));
info.true_fluorescence.on = true_on_fl;

info.shuffle_distr.num_shuffles = num_shuffles;
percentiles_x = [5 25 50 75 95];
info.shuffle_distr.x = percentiles_x;
info.shuffle_distr.y = prctile(shuffled_fl, percentiles_x);

% Optional visualization
if (show_cdf)
    [F,x] = ecdf(shuffled_fl);
    plot(x,F,'.-');
    xlabel('Mean fluorescence over trial');
    ylabel('Cumulative fraction');
    grid on;
    hold on;
    plot(true_on_fl*[1 1], [0 1], 'r--', 'LineWidth', 2);
    hold off;
    legend('Shuffle',...
           sprintf('Observed (p_L=%.4f, p_U=%.4f)',p_lower,p_upper),...
           'Location', 'SouthEast');
end