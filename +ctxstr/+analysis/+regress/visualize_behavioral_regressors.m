function visualize_behavioral_regressors(trials, st_trial_inds, t,...
            velocity, accel,...
            lick_times, lick_rate,...
            reward_frames, motion_frames)
        
sp = @(m,n,p) subtightplot(m, n, p, [0.01 0.05], 0.04, 0.04); % Gap, Margin-X, Margin-Y

num_trials = length(trials);

h_axes = zeros(3,1);

clf;

h_axes(1) = sp(3,1,1);
v_lims = [-0.15 1.15];
hold on;
for k = 1:num_trials
    trial = trials(k);
    t_lims = [trial.start_time trial.us_time];
    [v_k, t_k] = ctxstr.core.get_traces_by_time(velocity, t, t_lims);
    if ismember(k, st_trial_inds)
        plot(t_k, v_k, 'k.-');
    else
        plot(t_k, v_k, 'k:');
    end
    
    if ~isempty(trial.motion.onsets)
        plot_vertical_lines(trial.motion.onsets, v_lims, 'r:');
    end
end
plot(t([1 end]), [0 0], 'k:');
plot_vertical_lines([trials.us_time], v_lims, 'b:');
st_reward_times = t(reward_frames);
st_motion_frames = t(motion_frames);
plot(st_reward_times, ones(size(st_reward_times)), 'b.', 'MarkerSize', 18);
plot(st_motion_frames, ones(size(st_motion_frames)), 'r.', 'MarkerSize', 18);
hold off;
ylim(v_lims);
ylabel('Velocity (norm.)');
set(gca, 'YTick', 0:0.25:1);

h_axes(2) = sp(3,1,2);
a_lims = [-1 1];
hold on;
for k = 1:num_trials
    trial = trials(k);
    t_lims = [trial.start_time trial.us_time];
    [a_k, t_k] = ctxstr.core.get_traces_by_time(accel, t, t_lims);
    if ismember(k, st_trial_inds)
        plot(t_k, a_k, 'k.-');
    else
        plot(t_k, a_k, 'k:');
    end
    
    if ~isempty(trial.motion.onsets)
        plot_vertical_lines(trial.motion.onsets, a_lims, 'r:');
    end
end
plot(t([1 end]), [0 0], 'k:');
plot_vertical_lines([trials.us_time], a_lims, 'b:');
hold off;
ylim(a_lims);
ylabel('Accel (norm.)');
set(gca, 'YTick', -1:0.25:1);

h_axes(3) = sp(3,1,3);
l_lims = [-0.15 1.15];
hold on;
plot(lick_times, 1.075*ones(size(lick_times)), 'b.');
plot(t, lick_rate, 'k.-');
plot(t([1 end]), [0 0], 'k:');
plot_vertical_lines([trials.us_time], l_lims, 'b:');
hold off;
ylabel('Lick rate (norm.)');
ylim(l_lims);
xlabel('Trial');
set(gca, 'YTick', 0:0.25:1);

linkaxes(h_axes, 'x');
xlim([trials(st_trial_inds(1)).start_time trials(st_trial_inds(end)).us_time]);
zoom xon;
set(h_axes, 'TickLength', [0.001 0]);
set(h_axes, 'XTick', [trials(st_trial_inds).start_time]);
set(h_axes(1:end-1), 'XTickLabel', []);
set(h_axes(end), 'XTickLabel', st_trial_inds);

subplot(h_axes(1));