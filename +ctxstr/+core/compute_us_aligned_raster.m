function [R_us, t_us, info] = compute_us_aligned_raster(trials_to_use, trials, trace_cont, time_cont)
% Raster contains all trials from the behavioral session. Thus, the trial
% index in the raster directly matches trial numbers in the behavioral record.

num_all_trials = length(trials);

post_us_padding = 1; % s
t_us_lims = [Inf post_us_padding];

traces = cell(num_all_trials, 1);
trial_times = cell(num_all_trials, 1);

% First, parse out traces and intra-trial time for each trial
for k = 1:num_all_trials
    if ismember(k, trials_to_use)
        trial = trials(k);

        [traces{k}, times_k] = ctxstr.core.get_traces_by_time(...
            trace_cont, time_cont, [trial.start_time, trial.us_time+post_us_padding]);
        trial_times{k} = times_k - trial.us_time; % Time relative to US

        if trial_times{k}(1) < t_us_lims(1)
            t_us_lims(1) = trial_times{k}(1);
        end
    end
end

% Next, resample traces using a common timebase for all trials
num_samples = ceil(diff(t_us_lims) * 15); % At least 15 samples per s
t_us = linspace(t_us_lims(1), t_us_lims(2), num_samples);
R_us = zeros(num_all_trials, num_samples);
for k = 1:num_all_trials
    if ismember(k, trials_to_use)
        R_us(k,:) = interp1(trial_times{k}, traces{k}, t_us, 'linear', NaN);
    else
        R_us(k,:) = NaN(1, num_samples);
    end
end

% Auxiliary information
info.trial_inds = trials_to_use;
info.traces = traces;
info.trial_times = trial_times;
info.t_lims = t_us_lims;