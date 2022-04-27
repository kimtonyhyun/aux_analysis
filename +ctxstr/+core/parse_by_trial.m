function [traces_by_trial, trial_times] = parse_by_trial(traces, t, trials, trials_to_parse)

num_all_trials = length(trials);

traces_by_trial = cell(1, num_all_trials);
trial_times = cell(1, num_all_trials);

for k = trials_to_parse
    trial = trials(k);
    trial_time = [trial.start_time, trial.us_time];
    
    [traces_by_trial{k}, trial_times{k}] = ...
        ctxstr.core.get_traces_by_time(traces, t, trial_time);
end