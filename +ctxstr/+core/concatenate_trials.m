function conc_traces = concatenate_trials(traces_by_trial, trials_to_use)

conc_traces = cell2mat(traces_by_trial(trials_to_use));