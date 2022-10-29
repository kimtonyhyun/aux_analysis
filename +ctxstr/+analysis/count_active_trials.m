function [num_active_trials, active_frac] = count_active_trials(cell_idx, binned_traces_by_trial, trial_inds)

num_active_trials = 0;

for k = trial_inds
    trace_k = binned_traces_by_trial{k}(cell_idx,:);
    if any(trace_k)
        num_active_trials = num_active_trials + 1;
    end
end

active_frac = num_active_trials / length(trial_inds);