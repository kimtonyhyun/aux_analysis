function [trial_inds, num_trials] = find_opto_trials(saleae_file)
% Returns logical vectors indicating whether the trial was
% a real/sham opto trial or non-opto trial.
%
% Makes use of the fact that the shutter TTL slightly lags
% the trial clock transitions.

real_shutter_ch = 0;
sham_shutter_ch = 1;
trial_clk_ch = 2;

trials = find_pulses(saleae_file, trial_clk_ch);
num_trials = size(trials,1);

realopto_edges = find_edges(saleae_file, real_shutter_ch);
num_realopto = size(realopto_edges, 1);

shamopto_edges = find_edges(saleae_file, sham_shutter_ch);
num_shamopto = size(shamopto_edges, 1);

fprintf('Found %d trials total, of which:\n', num_trials);
fprintf('  - %d are REAL opto trials\n', num_realopto);
fprintf('  - %d are SHAM opto trials\n', num_shamopto);

realopto_trials = false(1, num_trials);
shamopto_trials = false(1, num_trials);

for k = 1:num_realopto
    t = find(realopto_edges(k)>trials(:,1),1,'last');
    realopto_trials(t) = true;
end

for k = 1:num_shamopto
    t = find(shamopto_edges(k)>trials(:,1),1,'last');
    shamopto_trials(t) = true;
end

trial_inds.real = realopto_trials;
trial_inds.sham = shamopto_trials;
trial_inds.off = ~(realopto_trials | shamopto_trials);