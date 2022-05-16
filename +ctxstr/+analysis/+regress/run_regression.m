clear;

load('resampled_data.mat');

reward_pre = 1.5; % s
reward_post = 1.5;

motion_pre = 1;
motion_post = 4;

%% Align behavioral regressors to neural data sampling rate

% Reward and motion onset times
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

% Resample velocity trace to align with neural data
velocity = interp1(session.behavior.velocity(:,1), session.behavior.velocity(:,2), t);
accel = ctxstr.analysis.compute_derivative(t, velocity);

lick_times = session.behavior.lick_times;
lick_rate = ctxstr.behavior.compute_lick_rate(lick_times, t, 0.25);

% Normalize
velocity = velocity / max(abs(velocity));
accel = accel / max(abs(accel));
lick_rate = lick_rate / max(lick_rate);

%% Low-pass filter velocity trace

cutoff_freq = 1.5; % Hz
v_filt = ctxstr.analysis.filter_trace(velocity, cutoff_freq, fps);
a_filt = ctxstr.analysis.filter_trace(accel, cutoff_freq, fps);
lr_filt = ctxstr.analysis.filter_trace(lick_rate, cutoff_freq, fps);

ctxstr.analysis.regress.visualize_filtered_regressors(trials, st_trial_inds, t,...
    velocity, v_filt,...
    accel, a_filt,...
    lick_times, lick_rate, lr_filt);
title(sprintf('%s: Temporally-filtered behavioral regressors', dataset_name));

%% Visualization #1: Sanity check plot of behavioral regressors + example neurons

ctx_inds_to_show = [18 41 15 21];
str_inds_to_show = [32 66];
ctxstr.analysis.regress.visualize_regressors(trials, st_trial_inds,...
    t, ctx_traces, ctx_inds_to_show, str_traces, str_inds_to_show,...
    reward_frames, motion_frames, velocity);
title(sprintf('%s: Example neurons', dataset_name));

%% Define regressors

clear regressors;

regressors(1).name = 'reward';
regressors(1).trace = reward_frames;
regressors(1).pre_samples = round(reward_pre * fps); % frames
regressors(1).post_samples = round(reward_post * fps);

regressors(2).name = 'motion';
regressors(2).trace = motion_frames;
regressors(2).pre_samples = round(motion_pre * fps);
regressors(2).post_samples = round(motion_post * fps);

regressors(3).name = 'velocity';
regressors(3).trace = velocity;
regressors(3).pre_samples = round(0.5 * fps);
regressors(3).post_samples = round(0.5 * fps);

%% Fit neural activity from behavioral signals

% Perform regressions
[fitted_ctx_traces_st, ctx_fit_info] = ctxstr.analysis.regress.regress_from_behavior(...
    ctx_traces_by_trial, t, trials, st_trial_inds, regressors);

[fitted_str_traces_st, str_fit_info] = ctxstr.analysis.regress.regress_from_behavior(...
    str_traces_by_trial, t, trials, st_trial_inds, regressors);

% Parse results into trials
t_st = ctxstr.core.concatenate_trials(time_by_trial, st_trial_inds);
fitted_ctx_traces_by_trial = ctxstr.core.parse_into_trials(fitted_ctx_traces_st, t_st, trials);
fitted_str_traces_by_trial = ctxstr.core.parse_into_trials(fitted_str_traces_st, t_st, trials);

num_trials = length(trials);
ctx_residuals_by_trial = cell(1, num_trials);
str_residuals_by_trial = cell(1, num_trials);
for k = st_trial_inds
    ctx_residuals_by_trial{k} = ctx_traces_by_trial{k} - fitted_ctx_traces_by_trial{k};
    str_residuals_by_trial{k} = str_traces_by_trial{k} - fitted_str_traces_by_trial{k};
end

%% Visualization 2

for k = 41:ctx_info.num_cells
    show_fit(k, st_trial_inds, trials,...
        time_by_trial, ctx_traces_by_trial, fitted_ctx_traces_by_trial, ctx_residuals_by_trial,...
        ctx_fit_info);
    title(sprintf('%s: Ctx cell #=r%d', dataset_name, ctx_info.ind2rec(k)));
    zoom xon;
    
    pause;
end
