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
velocity = velocity / max(velocity);

%% Low-pass filter velocity trace

cutoff_freq = 1.5;
[b, a] = butter(2, cutoff_freq/(fps/2));
v_filt = filtfilt(b,a,velocity);
accel = (v_filt(2:end)-v_filt(1:end-1))/(1/fps);

figure;
ax1 = subplot(211);
plot(t, velocity, '.-');
hold on;
plot(t, v_filt', 'r');
hold off;

ax2 = subplot(212);
plot(t(1:end-1), accel);
grid on;

linkaxes([ax1 ax2], 'x');
zoom xon;

%% Visualization #1: Sanity check plot of behavioral regressors + example neurons

ctx_inds_to_show = [1 2 3];
str_inds_to_show = [1 2 3];
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

% Used for displaying regression results later
t_st = ctxstr.core.concatenate_trials(time_by_trial, st_trial_inds);
ctx_traces_st = ctxstr.core.concatenate_trials(ctx_traces_by_trial, st_trial_inds);
str_traces_st = ctxstr.core.concatenate_trials(str_traces_by_trial, st_trial_inds);
num_regressors = length(regressors);

% Perform regressions
[ctx_traces_fit_st, ctx_fit_info] = ctxstr.analysis.regress.regress_from_behavior(...
    ctx_traces_by_trial, t, trials, st_trial_inds, regressors);

[str_traces_fit_st, str_fit_info] = ctxstr.analysis.regress.regress_from_behavior(...
    str_traces_by_trial, t, trials, st_trial_inds, regressors);

%% Visualization 2

for k = 1:ctx_info.num_cells
    subplot(1,8,1:5);
    plot(t_st, ctx_traces_st(k,:), 'k');
    hold on;
    plot(t_st, ctx_traces_fit_st(k,:), 'r');
    hold off;
    title(sprintf('%s: Ctx cell #=r%d', dataset_name, ctx_info.ind2rec(k)));
    zoom xon;
    
    subplot(1,8,6);
    plot(ctx_fit_info(1).t, ctx_fit_info(1).kernel(k,:), 'b');
    title(ctx_fit_info(1).name);
    axis tight;
    ylim([-0.1 1]);
    
    subplot(1,8,7);
    plot(ctx_fit_info(2).t, ctx_fit_info(2).kernel(k,:), 'r');
    title(ctx_fit_info(2).name);
    axis tight;
    ylim([-0.1 1]);
    
    subplot(1,8,8);
    plot(ctx_fit_info(3).t, ctx_fit_info(3).kernel(k,:), 'r');
    title(ctx_fit_info(3).name);
    axis tight;
    ylim([-0.1 1]);
    
    pause;
end

%%

for k = 1:str_info.num_cells
    subplot(1,8,1:5);
    plot(t_st, str_traces_st(k,:), 'm');
    hold on;
    plot(t_st, str_traces_fit_st(k,:), 'r');
    hold off;
    title(sprintf('%s: Str cell #=r%d', dataset_name, str_info.ind2rec(k)));
    zoom xon;
    
    subplot(1,8,6);
    plot(str_fit_info.reward.t, str_fit_info.reward.kernel(k,:), 'b');
    axis tight;
    ylim([-0.1 1]);
    
    subplot(1,8,7);
    plot(str_fit_info.motion.t, str_fit_info.motion.kernel(k,:), 'r');
    axis tight;
    ylim([-0.1 1]);
    
    subplot(1,8,8);
    plot(str_fit_info.velocity.t, str_fit_info.velocity.kernel(k,:), 'r');
    axis tight;
    ylim([-0.1 1]);
    pause;
end