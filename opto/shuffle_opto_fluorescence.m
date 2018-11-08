function [p_lower, p_upper, info] = shuffle_opto_fluorescence(ds, cell_idx, laser_off_trials, laser_on_trials)
% Compute the p-value of observed opto effect, by performing random trial
% shuffles.
%
% Note: Currently assumes that there are 120 laser off trials and 40 laser
% on trials.

num_shuffles = 1e4;
show_cdf = false;

% Collect event information from cell
%------------------------------------------------------------
fluorescence_per_trial = compute_trial_mean_fluorescences(ds, cell_idx);

true_on_fl = mean(fluorescence_per_trial(laser_on_trials));

% Next, we will form subsamples of trials.
%------------------------------------------------------------
all_trials = union(laser_off_trials, laser_on_trials);
num_laser_on_trials = length(laser_on_trials);

shuffled_fl = zeros(1, num_shuffles);
for k = 1:num_shuffles
    trial_shuffle = randsample(all_trials, num_laser_on_trials);
    shuffled_fl(k) = mean(fluorescence_per_trial(trial_shuffle));
end

% Fraction of shuffles with number of opto events as FEW as the one
% observed.
p_lower = sum(shuffled_fl<=true_on_fl)/num_shuffles;

% Fraction of shuffles with number of opto events as MANY as the one
% observed
p_upper = sum(shuffled_fl>=true_on_fl)/num_shuffles;

% Additional info
%------------------------------------------------------------
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