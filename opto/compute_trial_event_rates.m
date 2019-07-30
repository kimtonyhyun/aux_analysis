function event_rate_per_trial = compute_trial_event_rates(ds, cell_idx)
% TODO: Count events over a specified sub-portion of a trial

event_rate_per_trial = zeros(ds.num_trials, 1);
for k = 1:ds.num_trials
    eventdata = ds.trials(k).events{cell_idx};
    num_events = size(eventdata,1);
    event_rate_per_trial(k) = num_events / ds.trials(k).time;
end