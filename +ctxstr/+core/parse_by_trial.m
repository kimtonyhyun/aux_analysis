function [traces_by_trial, trial_times] = parse_by_trial(traces, t, trials, trials_to_parse)

num_all_trials = length(trials);

traces_by_trial = cell(1, num_all_trials);
trial_times = cell(1, num_all_trials);

for k = trials_to_parse
    trial = trials(k);
    trial_time = [trial.start_time, trial.us_time];
    
    [traces_by_trial{k}, trial_times{k}] = ...
        ctxstr.core.get_traces_by_time(traces, t, trial_time);
    
    % Conversion to double needed for cell2mat concatenation, as in:
    %   cont_ctx_traces = cell2mat(ctx_traces_by_trial);
    % when working with Ca2+ traces which are stored as single.
    traces_by_trial{k} = double(traces_by_trial{k});
end