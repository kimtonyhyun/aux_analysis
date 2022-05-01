function visualize_regressors(trials, st_trial_inds,...
    t, ctx_traces, ctx_inds_to_show, str_traces, str_inds_to_show,...
    reward_frames, motion_frames, velocity)

sp = @(m,n,p) subtightplot(m, n, p, [0.01 0.05], 0.04, 0.04); % Gap, Margin-X, Margin-Y

num_trials = length(trials);
num_ctx_to_show = length(ctx_inds_to_show);
num_str_to_show = length(str_inds_to_show);

num_rows = 1 + num_ctx_to_show + num_str_to_show;
h_axes = zeros(num_rows, 1);

clf;
% First, show velocity, position, lick times, US and MO events. Non-ST
% trials are shown in dashed lines.
%------------------------------------------------------------
h_axes(1) = sp(num_rows,1,1);
hold on;
v_color = [0 0.447 0.741];
v_lims = [-0.15 1.15];
for k = 1:length(trials)
    trial = trials(k);
    t_lims = [trial.start_time trial.us_time];
    [vel_k, t_k] = ctxstr.core.get_traces_by_time(velocity, t, t_lims);
    if ismember(k, st_trial_inds)
        plot(t_k, vel_k, '.-', 'Color', v_color);
    else
        plot(t_k, vel_k, ':', 'Color', v_color);
    end
    
    plot(trial.lick_times, 0.95*v_lims(2)*ones(size(trial.lick_times)), 'b.');
    if ~isempty(trial.motion.onsets)
        plot_vertical_lines(trial.motion.onsets, v_lims, 'r:');
    end
end
plot_vertical_lines([trials.us_time], v_lims, 'b:');
hold off;
ylim(v_lims);
ylabel({'Velocity','(norm.)'});

% Next, show selected cortical traces, and highlight the reward and motion
% frames, in order to sanity check behavioral event alignment to the neural
% data sampling.
%------------------------------------------------------------
y_lims = [-0.15 1.15];
for i = 1:num_ctx_to_show
    ctx_idx = ctx_inds_to_show(i);
    tr = ctx_traces(ctx_idx,:);
    
    h_axes(1+i) = sp(num_rows, 1, 1+i);
    hold on;
    for k = 1:num_trials
        trial = trials(k);
        t_lims = [trial.start_time trial.us_time];
        [tr_k, t_k] = ctxstr.core.get_traces_by_time(tr, t, t_lims);
        if ismember(k, st_trial_inds)
            line_style = '.-'; % Solid, emphasize samples
        else
            line_style = ':'; % Faint dots
        end
        plot(t_k, tr_k, line_style, 'Color', 'k');
    end
    plot_vertical_lines([trials.us_time], y_lims, 'b:');
    plot(t(reward_frames), tr(reward_frames), 'bo');
    plot(t(motion_frames), tr(motion_frames), 'ro');
    hold off;
    ylim(y_lims);
    ylabel(sprintf('Ctx cell #=%d', ctx_idx));
end

% Then the same for striatal traces. TODO: Factor out common code.
%------------------------------------------------------------
for j = 1:num_str_to_show
    str_idx = str_inds_to_show(j);
    tr = str_traces(str_idx,:);
    
    h_axes(1+num_ctx_to_show+j) = sp(num_rows, 1, 1+num_ctx_to_show+j);
    hold on;
    for k = 1:num_trials
        trial = trials(k);
        t_lims = [trial.start_time trial.us_time];
        [tr_k, t_k] = ctxstr.core.get_traces_by_time(tr, t, t_lims);
        if ismember(k, st_trial_inds)
            line_style = '.-'; % Solid
        else
            line_style = ':'; % Faint dots
        end
        plot(t_k, tr_k, line_style, 'Color', 'm');
    end
    plot_vertical_lines([trials.us_time], y_lims, 'b:');
    plot(t(reward_frames), tr(reward_frames), 'bo');
    plot(t(motion_frames), tr(motion_frames), 'ro');
    hold off;
    ylim(y_lims);
    ylabel(sprintf('Str cell #=%d', str_idx));
end
xlabel('Trial index');

% Fix up display settings
%------------------------------------------------------------
linkaxes(h_axes, 'x');
set(h_axes, 'TickLength', [0.001 0]);
set(h_axes, 'XTick', [trials(st_trial_inds).start_time]);
set(h_axes(1:end-1), 'XTickLabel', []);
set(h_axes(end), 'XTickLabel', st_trial_inds);
set(h_axes(2:end), 'YTick', [0 1]);

xlim([trials(st_trial_inds(1)).start_time trials(st_trial_inds(end)).us_time]);
subplot(h_axes(1));
zoom xon;