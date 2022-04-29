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

%% Generate temporally offset regressors

X_reward = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
    reward_frames, reward_pre_samples, reward_post_samples); % [regressors x num_frames]
X_reward_by_trial = ctxstr.core.parse_into_trials(X_reward, t, trials);

X_motion = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
    motion_frames, motion_pre_samples, motion_post_samples);
X_motion_by_trial = ctxstr.core.parse_into_trials(X_motion, t, trials);

% Indicator variables showing the finite support of each event
reward_support = sum(X_reward,1) > 0;
reward_support_by_trial = ctxstr.core.parse_into_trials(reward_support, t, trials);

motion_support = sum(X_motion,1) > 0;
motion_support_by_trial = ctxstr.core.parse_into_trials(motion_support, t, trials);

%% Visualization #1: Sanity check plot of behavioral regressors + example neurons

ctx_inds_to_show = [6 14 29];
str_inds_to_show = [46 53 76];
ctxstr.analysis.regress.visualize_regressors(session, trials, st_trial_inds,...
    t, ctx_traces, ctx_inds_to_show, str_traces, str_inds_to_show,...
    reward_frames, motion_frames,...
    'reward_support', reward_support,...
    'motion_support', []);
title(dataset_name);

%% Correlations between neural activity and the behavioral indicator variables

[~, corrlist_ctx_reward] = ctxstr.analysis.corr.compute_corr_over_trials(...
    ctx_traces_by_trial, reward_support_by_trial, st_trial_inds, 'descend');
[~, corrlist_str_reward] = ctxstr.analysis.corr.compute_corr_over_trials(...
    ctx_traces_by_trial, reward_support_by_trial, st_trial_inds, 'descend');

%% Try regression

t_st = ctxstr.core.concatenate_trials(time_by_trial, st_trial_inds);
y = ctx_traces_st(6,:)'; % [num_frames x 1]

X_reward_st = ctxstr.core.concatenate_trials(X_reward_by_trial, st_trial_inds);
X_motion_st = ctxstr.core.concatenate_trials(X_motion_by_trial, st_trial_inds);

A = cat(1, X_reward_st, X_motion_st)'; % [num_frames x num_regressors]

theta = (A'*A)\A'*y;

y_fit = A*theta;

