function count_active_trials(cell_idx, binned_traces_by_trial, trial_inds)

num_trials = length(trial_inds);
num_active_trials = 0;

for k = trial_inds
    trace_k = binned_traces_by_trial{k}(cell_idx,:);
    if any(trace_k)
        num_active_trials = num_active_trials + 1;
    end
end

fprintf('Cell %d shows activity in %d out of %d trials (%.1f%%)\n',...
    cell_idx, num_active_trials, num_trials,...
    100*num_active_trials/num_trials);