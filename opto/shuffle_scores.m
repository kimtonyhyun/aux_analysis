function [p_lower, p_upper, info] = shuffle_scores(scores, laser_off_trials, laser_on_trials, num_shuffles)
% Compute the p-value of observed opto effect, by performing shuffles.

% Sample the same number of trials as `laser_on_trials`, but from both
% laser_off_trials and laser_on_trials
all_trials = union(laser_off_trials, laser_on_trials);
num_laser_on_trials = length(laser_on_trials);

shuffles = zeros(1, num_shuffles);
for k = 1:num_shuffles
    trial_shuffle = randsample(all_trials, num_laser_on_trials);
    shuffles(k) = mean(scores(trial_shuffle));
end

true_on_score = mean(scores(laser_on_trials));

% Fraction of shuffles with score as SMALL as the one observed during opto
p_lower = sum(shuffles<=true_on_score)/num_shuffles;

% Fraction of shuffles with score as LARGE as the one observed during opto
p_upper = sum(shuffles>=true_on_score)/num_shuffles;

% Additional info
%------------------------------------------------------------
info.true_scores.all = scores;
info.true_scores.off = mean(scores(laser_off_trials));
info.true_scores.on = true_on_score;

info.shuffle_distr.num_shuffles = num_shuffles;
percentiles_x = [5 25 50 75 95];
info.shuffle_distr.x = percentiles_x;
info.shuffle_distr.y = prctile(shuffles, percentiles_x);