function [R_mo, t_mo, info] = compute_mo_aligned_raster(trials_to_use, trials, trace_cont, time_cont)
% Compute cell activity raster with respect to motion onset (MO). Note that
% some trials may _not_ have an identified motion onset time, whereas other
% trials may have multiple identified motion onsets.
%
% Raster contains all trials from the behavioral session. Thus, the trial
% index in the raster directly matches trial numbers in the behavioral record.

num_all_trials = length(trials);

post_mo_padding = 1; % s
t_mo_lims = [Inf -Inf];

traces = cell(num_all_trials, 1);
trial_times = cell(num_all_trials, 1);

% First, parse out traces and intra-trial time for each trial containing a
% motion onset.
for k = 1:num_all_trials
    if ismember(k, trials_to_use)
        trial = trials(k);

        % Some trials may not have an identified motion onset time
        if ~isempty(trial.motion.onsets)
            mo_time = trial.motion.onsets(1); % FIXME: Handle multiple MOs in trial

            [traces{k}, times_k] = ctxstr.core.get_traces_by_time(...
                trace_cont, time_cont, [trial.start_time, trial.us_time+post_mo_padding]);
            trial_times{k} = times_k - mo_time; % Time relative to MO

            if trial_times{k}(1) < t_mo_lims(1)
                t_mo_lims(1) = trial_times{k}(1);
            end
            if trial_times{k}(end) > t_mo_lims(2)
                t_mo_lims(2) = trial_times{k}(end);
            end
        end % trial.motion.onsets
    end
end

% Next, resample traces using a common timebase for all trials
num_samples = ceil(diff(t_mo_lims) * 15); % At least 15 samples per s
t_mo = linspace(t_mo_lims(1), t_mo_lims(2), num_samples);
R_mo = zeros(num_all_trials, num_samples);
for k = 1:num_all_trials
    if ismember(k, trials_to_use) && ~isempty(trial_times{k})
        R_mo(k,:) = interp1(trial_times{k}, traces{k}, t_mo, 'linear', NaN);
    else
        R_mo(k,:) = NaN(size(t_mo));
    end
end

% Auxiliary information
info.traces = traces;
info.trial_times = trial_times;
info.t_lims = t_mo_lims;
info.trial_inds = trials_to_use;