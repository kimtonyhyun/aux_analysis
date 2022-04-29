function [C, corrlist] = compute_corr_over_trials(traces1_by_trial, traces2_by_trial, trials_for_corr, corrlist_sort_dir)

traces1 = ctxstr.core.concatenate_trials(traces1_by_trial, trials_for_corr); % [cells x time]
traces2 = ctxstr.core.concatenate_trials(traces2_by_trial, trials_for_corr);

C = corr(traces1', traces2'); % corr works column-wise
corrlist = corr_to_corrlist(C);

if exist('corrlist_sort_dir', 'var')
    corrlist = sortrows(corrlist, 3, corrlist_sort_dir); % Sort by correlation value
end