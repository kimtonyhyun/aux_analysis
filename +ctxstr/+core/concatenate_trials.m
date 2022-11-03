function conc_traces = concatenate_trials(traces_by_trial, trials_to_use)

if ~exist('trials_to_use', 'var')
    trials_to_use = 1:length(traces_by_trial);
end

conc_traces = cell2mat(traces_by_trial(trials_to_use));