function [R_us, t_us, info] = compute_us_aligned_raster(cell_idx, trials_to_use, trials, imdata)

num_trials = length(trials_to_use);
t_us_lims = [Inf 0];

traces = cell(num_trials, 1);
trial_times = cell(num_trials, 1);

% First, parse out traces and intra-trial time for each trial
for k = 1:num_trials
    trial_ind = trials_to_use(k);
    trial = trials(trial_ind);
    
    [frames_k, times_k] = ctxstr.core.find_frames_in_trial(imdata.t, [trial.start_time, trial.us_time]); % No padding
    traces{k} = imdata.traces(cell_idx, frames_k);
    trial_times{k} = times_k - trial.us_time; % Time relative to US
    
    if trial_times{k}(1) < t_us_lims(1)
        t_us_lims(1) = trial_times{k}(1);
    end
end

% Next, resample traces using a common timebase for all trials
num_samples = ceil(diff(t_us_lims) * 15); % At least 15 samples per s
t_us = linspace(t_us_lims(1), t_us_lims(2), num_samples);
R_us = zeros(num_trials, num_samples);
for k = 1:num_trials
    R_us(k,:) = interp1(trial_times{k}, traces{k}, t_us, 'linear', NaN);
end

% Auxiliary information
info.n = num_trials;
info.traces = traces;
info.trial_times = trial_times;
info.t_lims = t_us_lims;