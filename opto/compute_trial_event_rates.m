function event_rate_per_trial = compute_trial_event_rates(ds, cell_idx, event_type)
% TODO: Count events over a specified sub-portion of a trial

event_rate_per_trial = zeros(ds.num_trials, 1);
for k = 1:ds.num_trials
    eventdata = ds.trials(k).events{cell_idx};
    switch event_type
        case 'num_events'
            e = size(eventdata,1);
        case 'event_amp_sum'
            e = sum(eventdata(:,3));
    end
    event_rate_per_trial(k) = e / ds.trials(k).time;
end