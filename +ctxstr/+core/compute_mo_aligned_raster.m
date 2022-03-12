function [R_mo, t_mo, info] = compute_mo_aligned_raster(cell_idx, trials_to_use, trials, imdata)
% Compute cell activity raster with respect to motion onset (MO). Note that
% some trials may _not_ have an identified motion onset time, whereas other
% trials may have multiple identified motion onsets.

num_trials = length(trials_to_use);
t_mo_lims = [Inf -Inf];

traces = cell(num_trials, 1);
trial_times = cell(num_trials, 1);
orig_trial_inds = zeros(num_trials, 1);

% First, parse out traces and intra-trial time for each trial containing a
% motion onset.
n = 0;
for k = 1:num_trials
    trial_ind = trials_to_use(k);
    trial = trials(trial_ind);
    
    % Some trials may not have an identified motion onset time
    if ~isempty(trial.motion.onsets)
        n = n + 1;
        orig_trial_inds(n) = trial_ind;
        
        mo_time = trial.motion.onsets(1); % FIXME: Handle multiple MOs in trial
        
        [frames_k, times_k] = ctxstr.core.find_frames_in_trial(imdata.t, [trial.start_time, trial.us_time]); % No padding
        traces{n} = imdata.traces(cell_idx, frames_k);
        trial_times{n} = times_k - mo_time; % Time relative to MO

        if trial_times{n}(1) < t_mo_lims(1)
            t_mo_lims(1) = trial_times{n}(1);
        end
        if trial_times{n}(end) > t_mo_lims(2)
            t_mo_lims(2) = trial_times{n}(end);
        end
    end % trial.motion.onsets
end
traces = traces(1:n);
trial_times = trial_times(1:n);
orig_trial_inds = orig_trial_inds(1:n);

% Next, resample traces using a common timebase for all trials
num_samples = ceil(diff(t_mo_lims) * 15); % At least 15 samples per s
t_mo = linspace(t_mo_lims(1), t_mo_lims(2), num_samples);
R_mo = zeros(n, num_samples);
for k = 1:n
    R_mo(k,:) = interp1(trial_times{k}, traces{k}, t_mo, 'linear', NaN);
end

% Auxiliary information
info.n = n;
info.traces = traces;
info.trial_times = trial_times;
info.t_lims = t_mo_lims;
info.orig_trial_inds = orig_trial_inds;