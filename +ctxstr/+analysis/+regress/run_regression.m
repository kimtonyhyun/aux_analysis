%% Regression parameters

reward_pre_samples = round(1.5 * fps); % frames
reward_post_samples = round(1.5 * fps);

motion_pre_samples = round(1 * fps);
motion_post_samples = round(4 * fps);

%% Subselect and align behavioral events to neural data sampling rate

selected_reward_times = [];
selected_motion_times = [];
for trial_idx = st_trial_inds
    trial = trials(trial_idx);
    
    % For each stereotyped trial, we include the two US'es that define the
    % start and end of the trial. Duplicate entries are removed below.
    selected_reward_times = [selected_reward_times trial.start_time trial.us_time]; %#ok<*AGROW>
    selected_motion_times = [selected_motion_times trial.motion.onsets];
end
selected_reward_times = unique(selected_reward_times);

reward_frames = ctxstr.core.assign_events_to_frames(selected_reward_times, t);
motion_frames = ctxstr.core.assign_events_to_frames(selected_motion_times, t);

%% Fit neural activity from behavioral signals

% Used for displaying regression results
t_st = ctxstr.core.concatenate_trials(time_by_trial, st_trial_inds);
ctx_traces_st = ctxstr.core.concatenate_trials(ctx_traces_by_trial, st_trial_inds);
str_traces_st = ctxstr.core.concatenate_trials(str_traces_by_trial, st_trial_inds);

% Perform regressions
[ctx_traces_fit_st, ctx_fit_info] = ctxstr.analysis.regress.regress_from_behavior(...
    ctx_traces_by_trial, t, trials, st_trial_inds,...
    reward_frames, reward_pre_samples, reward_post_samples,...
    motion_frames, motion_pre_samples, motion_post_samples);

[str_traces_fit_st, str_fit_info] = ctxstr.analysis.regress.regress_from_behavior(...
    str_traces_by_trial, t, trials, st_trial_inds,...
    reward_frames, reward_pre_samples, reward_post_samples,...
    motion_frames, motion_pre_samples, motion_post_samples);

reward_support_by_trial = ctxstr.core.parse_into_trials(ctx_fit_info.reward.support, t, trials);
motion_support_by_trial = ctxstr.core.parse_into_trials(ctx_fit_info.motion.support, t, trials);

%% Correlations between neural activity and the indicator variables

% Note that correlation to motion onset indicator will not be very useful
% later in training, because the motion onset pre/post windows will cover
% most of a trial duration. For this purpose, may be more useful to use
% short pre/post windows for motion onset.
[~, corrlist_ctx_reward] = ctxstr.analysis.corr.compute_corr_over_trials(...
    ctx_traces_by_trial, reward_support_by_trial, st_trial_inds, 'descend');
[~, corrlist_ctx_motion] = ctxstr.analysis.corr.compute_corr_over_trials(...
    ctx_traces_by_trial, motion_support_by_trial, st_trial_inds, 'descend');

[~, corrlist_str_reward] = ctxstr.analysis.corr.compute_corr_over_trials(...
    str_traces_by_trial, reward_support_by_trial, st_trial_inds, 'descend');
[~, corrlist_str_motion] = ctxstr.analysis.corr.compute_corr_over_trials(...
    str_traces_by_trial, motion_support_by_trial, st_trial_inds, 'descend');

%% Visualization #1A: Sanity check plot of behavioral regressors + example neurons

ctx_inds_to_show = corrlist_ctx_reward(1:3,1);
str_inds_to_show = corrlist_str_reward(1:3,1);
ctxstr.analysis.regress.visualize_regressors(session, trials, st_trial_inds,...
    t, ctx_traces, ctx_inds_to_show, str_traces, str_inds_to_show,...
    reward_frames, motion_frames,...
    'reward_support_by_trial', reward_support_by_trial);
title(sprintf('%s: Example reward-correlated neurons', dataset_name));

%% Visualization #1B

ctx_inds_to_show = corrlist_ctx_motion(1:3,1);
str_inds_to_show = corrlist_str_motion(1:3,1);
ctxstr.analysis.regress.visualize_regressors(session, trials, st_trial_inds,...
    t, ctx_traces, ctx_inds_to_show, str_traces, str_inds_to_show,...
    reward_frames, motion_frames,...
    'motion_support_by_trial', motion_support_by_trial);
title(sprintf('%s: Example motion-correlated neurons', dataset_name));

%% Visualization 2

for k = 1:ctx_info.num_cells
    subplot(1,7,1:5);
    plot(t_st, ctx_traces_st(k,:), 'k-');
    hold on;
    plot(t_st, ctx_traces_fit_st(k,:), 'r');
    hold off;
    title(sprintf('%s: Ctx cell #=r%d', dataset_name, ctx_info.ind2rec(k)));
    zoom xon;
    
    subplot(1,7,6);
    plot(ctx_fit_info.reward.t, ctx_fit_info.reward.kernel(:,k), 'b');
    axis tight;
    ylim([-0.1 1]);
    
    subplot(1,7,7);
    plot(ctx_fit_info.motion.t, ctx_fit_info.motion.kernel(:,k), 'r');
    axis tight;
    ylim([-0.1 1]);
    pause;
end

%%

for k = 1:str_info.num_cells
    subplot(1,7,1:5);
    plot(t_st, str_traces_st(k,:), 'k-');
    hold on;
    plot(t_st, str_traces_fit_st(k,:), 'r');
    hold off;
    title(sprintf('%s: Str cell #=r%d', dataset_name, str_info.ind2rec(k)));
    zoom xon;
    
    subplot(1,7,6);
    plot(t_reward, theta_str(reward_inds, k), 'b');
    ylim([-0.1 1]);
    
    subplot(1,7,7);
    plot(t_motion, theta_str(motion_ind_start:end, k), 'r');
    ylim([-0.1 1]);
    pause;
end