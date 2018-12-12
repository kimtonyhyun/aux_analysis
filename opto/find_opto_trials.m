function [trial_inds, trial_times] = find_opto_trials(saleae_file, trial_clk_ch, real_shutter_ch, sham_shutter_ch)
% Returns trial indices indicating whether the trial was
% a real/sham opto trial or non-opto. Sham channel is optional.
%
% Makes use of the fact that the shutter TTL slightly lags
% the trial clock transitions.

% Load data
data = csvread(saleae_file);
times = data(:,1);
trial_clk = data(:,2+trial_clk_ch);
num_samples = length(times);

% First, go through the trial clock and identify all positive edges
%------------------------------------------------------------
trial_times = [];
for k = 2:num_samples
    if (~trial_clk(k-1) && trial_clk(k)) % Positive edge
        trial_times = [trial_times, times(k)]; %#ok<AGROW>
    end
end
num_trials = length(trial_times);

% Second, evaluate whether the shutter signal was active during the trial.
% We check the shutter state 0.1 seconds _after_ the start of the trial.
%------------------------------------------------------------
real_shutter = interp1(times, data(:,2+real_shutter_ch),...
    trial_times + 0.1);

if ~isempty(sham_shutter_ch)
    sham_shutter = interp1(times, data(:,2+sham_shutter_ch),...
        trial_times + 0.1);
else
    sham_shutter = zeros(size(trial_times));
end

fprintf('Found %d trials total, of which:\n', num_trials);
fprintf('  - %d are REAL opto trials\n', sum(real_shutter));
fprintf('  - %d are SHAM opto trials\n', sum(sham_shutter));

trial_inds.real = find(real_shutter);
trial_inds.sham = find(sham_shutter);
trial_inds.off = setdiff(1:num_trials, [trial_inds.real trial_inds.sham]);