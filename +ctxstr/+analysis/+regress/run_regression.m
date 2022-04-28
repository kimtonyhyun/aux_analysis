%% Regression parameters

num_frames = length(t);

reward_pre_samples = round(1.5 * fps); % frames
reward_post_samples = round(1.5 * fps);

motion_pre_samples = round(1 * fps);
motion_post_samples = round(4 * fps);

%% Align behavioral events to neural data sampling rate

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

%% Correlations between neural activity and the behavioral indicator variables

ctx_traces_st = ctxstr.core.concatenate_trials(ctx_traces_by_trial, st_trial_inds);
str_traces_st = ctxstr.core.concatenate_trials(str_traces_by_trial, st_trial_inds);

reward_support_st = ctxstr.core.concatenate_trials(reward_support_by_trial, st_trial_inds);
motion_support_st = ctxstr.core.concatenate_trials(motion_support_by_trial, st_trial_inds);

C_ctx_reward = corr(ctx_traces_st', reward_support_st');
C_str_reward = corr(str_traces_st', reward_support_st');

%% Try regression

t_st = ctxstr.core.concatenate_trials(time_by_trial, st_trial_inds);
y = ctx_traces_st(72,:)'; % [num_frames x 1]

X_reward_st = ctxstr.core.concatenate_trials(X_reward_by_trial, st_trial_inds);
X_motion_st = ctxstr.core.concatenate_trials(X_motion_by_trial, st_trial_inds);

A = cat(1, X_reward_st, X_motion_st)'; % [num_frames x num_regressors]

theta = (A'*A)\A'*y;

y_fit = A*theta;

%% Visualization #1: Sanity check plot of behavior + example neurons (WIP)

sp = @(m,n,p) subtightplot(m, n, p, [0.01 0.05], 0.04, 0.04); % Gap, Margin-X, Margin-Y

trials_to_show = st_trial_inds;
% ctx_inds_to_show = [41 15 21];
ctx_inds_to_show = [41 18 72 41 7 15];
str_inds_to_show = [55 137 67 160 169];

num_ctx_to_show = length(ctx_inds_to_show);
num_str_to_show = length(str_inds_to_show);

num_rows = 1+num_ctx_to_show+num_str_to_show;
h_axes = zeros(num_rows, 1);

clf;
h_axes(1) = sp(num_rows,1,1);
yyaxis left;
hold on;
for k = 1:length(trials)
    vel = trials(k).velocity;
    if ismember(k, st_trial_inds)
        plot(vel(:,1), vel(:,2), '-');
    else
        plot(vel(:,1), vel(:,2), ':');
    end
end
hold off;
ylim([-5 45]);
ylabel('Velocity (cm/s)');
yyaxis right;
y_lims = [0 session.behavior.position.us_threshold];
hold on;
for k = 1:length(trials)
    trial = trials(k);
    
    if ismember(k, st_trial_inds)
        plot(trial.position(:,1), trial.position(:,2), '-');
    else
        plot(trial.position(:,1), trial.position(:,2), ':');
    end
    
    plot(trial.lick_times, 0.95*y_lims(2)*ones(size(trial.lick_times)), 'b.');
    if ~isempty(trial.motion.onsets)
        plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
    end
end
plot_vertical_lines([trials.us_time], y_lims, 'b:');
ylim(y_lims);
ylabel('Position');
set(gca, 'TickLength', [0 0]);
title(dataset_name);

y_lims = [-0.15 1.15];
for i = 1:num_ctx_to_show
    h_axes(1+i) = sp(num_rows, 1, 1+i);
    ctx_idx = ctx_inds_to_show(i);
    
    ctx_trace = ctx_traces(ctx_idx,:);
    plot(t, ctx_trace, 'k.-');
    hold on;
    plot(t, reward_support, 'b');
%     plot(t, motion_support, 'r');
    plot_vertical_lines([trials.us_time], y_lims, 'b:');
    plot(t(reward_frames), ctx_trace(reward_frames), 'bo');
    plot(t(motion_frames), ctx_trace(motion_frames), 'ro');
    hold off;
    ylim(y_lims);
    ylabel(sprintf('Ctx cell #=%d', ctx_idx));
end

for j = 1:num_str_to_show
    h_axes(1+num_ctx_to_show+j) = sp(num_rows, 1, 1+num_ctx_to_show+j);
    str_idx = str_inds_to_show(j);
    
    str_trace = str_traces(str_idx,:);
    plot(t, str_trace, 'm.-');
    hold on;
    plot(t, reward_support, 'b');
%     plot(t, motion_support, 'r');
    plot_vertical_lines([trials.us_time], y_lims, 'b:');
    plot(t(reward_frames), str_trace(reward_frames), 'bo');
    plot(t(motion_frames), str_trace(motion_frames), 'ro');
    hold off;
    ylim(y_lims);
    ylabel(sprintf('Str cell #=%d', str_idx));
end
xlabel('Trial index');

linkaxes(h_axes, 'x');
set(h_axes, 'TickLength', [0.001 0]);
set(h_axes, 'XTick', [trials(trials_to_show).start_time]);
set(h_axes(1:end-1), 'XTickLabel', []);
set(h_axes(end), 'XTickLabel', trials_to_show);
set(h_axes(2:end), 'YTick', [0 1]);

xlim([trials(trials_to_show(1)).start_time trials(trials_to_show(end)).us_time]);
zoom xon;