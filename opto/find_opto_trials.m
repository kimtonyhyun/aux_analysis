function trial_inds = find_opto_trials(saleae_file)
% Returns logical vectors indicating whether the trial was
% a real/sham opto trial or non-opto trial.
%
% Makes use of the fact that the shutter TTL slightly lags
% the trial clock transitions.

trials = find_pulses(saleae_file, 3); % Ch 3
num_trials = size(trials,1);

realopto_edges = find_edges(saleae_file, 0);
num_realopto = size(realopto_edges, 1);

shamopto_edges = find_edges(saleae_file, 1);
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
trial_inds.none = ~(realopto_trials | shamopto_trials);