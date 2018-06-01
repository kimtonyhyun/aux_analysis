function [trial_inds, trial_times] = find_opto_trials(saleae_file, trial_clk_ch, real_shutter_ch, sham_shutter_ch)
% Returns trial indices indicating whether the trial was
% a real/sham opto trial or non-opto. Sham channel is optional.
%
% Makes use of the fact that the shutter TTL slightly lags
% the trial clock transitions.

trials = find_pulses(saleae_file, trial_clk_ch);
trial_times = trials(:,1);
num_trials = size(trials,1);

realopto_edges = find_edges(saleae_file, real_shutter_ch);
num_realopto = size(realopto_edges, 1);

if (exist('sham_shutter_ch', 'var') && ~isempty(sham_shutter_ch))
    shamopto_edges = find_edges(saleae_file, sham_shutter_ch);
    num_shamopto = size(shamopto_edges, 1);
else
    shamopto_edges = [];
    num_shamopto = 0;
end

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

trials_logical.real = realopto_trials;
trials_logical.sham = shamopto_trials;
trials_logical.off = ~(realopto_trials | shamopto_trials);

trial_inds.real = find(trials_logical.real);
trial_inds.sham = find(trials_logical.sham);
trial_inds.off = find(trials_logical.off);