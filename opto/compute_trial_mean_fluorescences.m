function fluorescence_per_trial = compute_trial_mean_fluorescences(ds, cell_idx)

fluorescence_per_trial = zeros(ds.num_trials, 1);
full_trace = ds.get_trace(cell_idx);
for m = 1:ds.num_trials
    trial_inds = ds.trial_indices(m,:); % [Start CS US End]
    % Sample the trace from 0.5 s (assuming 30 Hz) prior to CS onset until
    % the end of the trial.
    tr = full_trace(trial_inds(2)-15:trial_inds(4));
    fluorescence_per_trial(m) = mean(tr);
end