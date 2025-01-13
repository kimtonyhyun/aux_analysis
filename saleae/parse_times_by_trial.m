function event_times_by_trial = parse_times_by_trial(event_times, trial_times)

num_trials = size(trial_times, 1);
event_times_by_trial = cell(num_trials, 1);

for k = 1:num_trials
    cond1 = event_times >= trial_times(k,1);
    cond2 = event_times <= trial_times(k,2);
    event_times_by_trial{k} = event_times(cond1 & cond2);
end