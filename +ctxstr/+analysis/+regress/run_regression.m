%% Regression parameters

t = ctx.t; % Neural data have been aligned to cortical samples
num_frames = length(t);

reward_pre_samples = round(1.5 * fps); % frames
reward_post_samples = round(1.5 * fps);

mo_pre_samples = 15; % mo: motion onset
mo_post_samples = 15;

%% Align behavioral events to neural data sampling rate

selected_reward_times = [];
selected_mo_times = [];
for trial_idx = st_trial_inds
    trial = trials(trial_idx);
    
    selected_reward_times = [selected_reward_times trial.us_time]; %#ok<*AGROW>
    selected_mo_times = [selected_mo_times trial.motion.onsets];
end

reward_frames = ctxstr.core.assign_events_to_frames(selected_reward_times, t);
mo_frames = ctxstr.core.assign_events_to_frames(selected_mo_times, t);

%% Generate temporally offset regressors

X_reward = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
    reward_frames, reward_pre_samples, reward_post_samples); % [regressors x num_frames]

X_mo = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
    mo_frames, mo_pre_samples, mo_post_samples);

% Indicator variables showing the finite support of each event
reward_active = sum(X_reward,1) > 0;
mo_active = sum(X_mo,1) > 0;

%% Correlations between neural activity and the behavioral indicator variables

cont_ctx_traces = cell2mat(ctx_traces_by_trial); % [cells x time]
cont_str_traces = cell2mat(str_traces_by_trial);
cont_reward_active = cell2mat(ctxstr.core.parse_by_trial(reward_active, t, trials, st_trial_inds));

C_ctx_reward = corr(cont_ctx_traces', cont_reward_active');

%% Try regression

y = cont_ctx_traces(41,:)'; % [num_frames x 1]

X_reward_by_trial = ctxstr.core.parse_by_trial(X_reward, t, trials, st_trial_inds);
cont_X_reward = cell2mat(X_reward_by_trial);
A = cont_X_reward'; % [num_frames x num_regressors]

theta = (A'*A)\A'*y;

%% Visualization #1: Sanity check plot of behavior + example neurons (WIP)

sp = @(m,n,p) subtightplot(m, n, p, [0.01 0.05], 0.04, 0.04); % Gap, Margin-X, Margin-Y

trials_to_show = st_trial_inds;
ctx_inds_to_show = [41 15 21];
% ctx_inds_to_show = [7 17 18];
str_inds_to_show = [55 32 66];

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
    
    ctx_trace = ctx.traces(ctx_idx,:);
    plot(ctx.t, ctx_trace, 'k.-');
    hold on;
    plot(t, reward_active, 'b');
%     plot(t, mo_indicator, 'r');
    plot_vertical_lines([trials.us_time], y_lims, 'b:');
    plot(ctx.t(reward_frames), ctx_trace(reward_frames), 'bo');
    plot(ctx.t(mo_frames), ctx_trace(mo_frames), 'ro');
    hold off;
    ylim(y_lims);
    ylabel(sprintf('Ctx cell #=%d', ctx_idx));
end

for j = 1:num_str_to_show
    h_axes(1+num_ctx_to_show+j) = sp(num_rows, 1, 1+num_ctx_to_show+j);
    str_idx = str_inds_to_show(j);
    
    str_trace = str.traces(str_idx,:);
    plot(str.t, str_trace, 'm.-');
    hold on;
    plot(t, reward_active, 'b');
%     plot(t, mo_indicator, 'r');
    plot_vertical_lines([trials.us_time], y_lims, 'b:');
    plot(str.t(reward_frames), str_trace(reward_frames), 'bo');
    plot(str.t(mo_frames), str_trace(mo_frames), 'ro');
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