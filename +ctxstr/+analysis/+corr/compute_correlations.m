%% Resample traces with a common timebase, then compute pairwise correlations

trials_for_corr = st_trial_inds;

resampled_ctx_traces = cell(1, num_all_trials);
resampled_str_traces = cell(1, num_all_trials);
common_time = cell(1, num_all_trials);

for k = trials_for_corr
    trial = trials(k);
    trial_time = [trial.start_time trial.us_time];
    
    [ctx_traces_k, ctx_times_k] = ctxstr.core.get_traces_by_time(ctx, trial_time);
    [str_traces_k, str_times_k] = ctxstr.core.get_traces_by_time(str, trial_time);
    
    if any(isnan(ctx_traces_k(:))) || any(isnan(str_traces_k(:)))
        trials_for_corr = setdiff(trials_for_corr, k);
        fprintf('Omitting Trial %d from correlation calculation due to NaNs\n', k);
    else
        [resampled_ctx_traces{k}, resampled_str_traces{k}, common_time{k}] = ctxstr.core.resample_ctxstr_traces(...
            ctx_traces_k, ctx_times_k, str_traces_k, str_times_k);
        
        % Needed for cell2mat concatenation (below), if working with Ca2+
        % traces which are stored as single
        resampled_ctx_traces{k} = double(resampled_ctx_traces{k});
        resampled_str_traces{k} = double(resampled_str_traces{k});
    end
end

cont_ctx_traces = cell2mat(resampled_ctx_traces); % [cells x time]
cont_str_traces = cell2mat(resampled_str_traces);

% Pearson correlations
C_ctx = corr(cont_ctx_traces');
C_str = corr(cont_str_traces');
C_ctxstr = corr(cont_ctx_traces', cont_str_traces');

%% Visualization #1: Correlation matrices and distribution of correlation values

ctxstr.vis.show_correlations(C_ctx, C_str, C_ctxstr, dataset_name);

%% Save correlation results

save('corrdata.mat', 'dataset_name', 'trials', 'trials_for_corr',...
        'common_time', 'resampled_ctx_traces', 'resampled_str_traces',...
        'ctx_info', 'str_info',...
        'C_ctx', 'C_str', 'C_ctxstr');
