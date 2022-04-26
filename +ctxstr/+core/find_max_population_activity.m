function [max_activity, max_trial_idx] = find_max_population_activity(traces_by_trial)

num_trials = length(traces_by_trial);

max_activity = 0;
max_trial_idx = 0;

for k = 1:num_trials
    traces_k = traces_by_trial{k};
    if ~isempty(traces_k)
        population_trace = sum(traces_k, 1); % Sum over neurons
        max_pop_trace = max(population_trace);
        if max_pop_trace > max_activity
            max_activity = max_pop_trace;
            max_trial_idx = k;
        end
    end
end