function show_ctxstr_trials(trials_to_show, session, trials, ctx, str, tdt)

num_trials_to_show = length(trials_to_show);

num_ctx_cells = size(ctx.traces,1);
num_d1_cells = length(tdt.pos);
num_d2_cells = length(tdt.neg);

sp = @(m,n,p) subtightplot(m, n, p, 0.02, 0.05, 0.05); % Gap, Margin-X, Margin-Y

p_lims = [0 session.behavior.position.us_threshold]; % Y-scale for encoder position
v_lims = [-5 max(session.behavior.velocity(:,2))];

% Compute Y-scale for mean pop. activity
ctx_max = ctx.fps * max(mean(ctx.traces, 1));
d1_max = str.fps * max(mean(str.traces(tdt.pos,:),1));
d2_max = str.fps * max(mean(str.traces(tdt.neg,:),1));
a_lims = [0 max([ctx_max d1_max d2_max])];

for k = 1:num_trials_to_show
    trial_idx = trials_to_show(k);
    trial = trials(trial_idx);
    
    t_lims = trial.times; % Includes trial padding
    
    ctx_frames = find_frames_in_trial(ctx.t, t_lims);
    ctx_t = ctx.t(ctx_frames);
    ctx_traces = ctx.fps * ctx.traces(:,ctx_frames); % Multiply CASCADE traces by fps for firing rate (Hz)
    mean_ctx_trace = mean(ctx_traces, 1);    
    
    str_frames = find_frames_in_trial(str.t, t_lims);
    str_t = str.t(str_frames);
    str_traces = str.fps * str.traces(:, str_frames);
    d1_traces = str_traces(tdt.pos, :);
    d2_traces = str_traces(tdt.neg, :);
    mean_d1_trace = mean(d1_traces, 1);
    mean_d2_trace = mean(d2_traces, 1);
    
%     a_lims = [0 1.1*max([mean_ctx_trace mean_d1_trace mean_d2_trace])]; % Y-scale for mean activity traces
    
    sp(5, num_trials_to_show, k);
    imagesc(ctx_t, 1:num_ctx_cells, ctx_traces);
    xlim(t_lims);
    title(sprintf('Trial %d', trial_idx));
    if k == 1
        ylabel('Ctx');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    sp(5, num_trials_to_show, num_trials_to_show+k);
    imagesc(str_t, 1:num_d1_cells, d1_traces); hold on;
    xlim(t_lims);
    if k == 1
        ylabel('Str (tdt-pos)');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    sp(5, num_trials_to_show, 2*num_trials_to_show+k);
    imagesc(str_t, 1:num_d2_cells, d2_traces); hold on;
    xlim(t_lims);
    if k == 1
        ylabel('Str (tdt-neg)');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    sp(5, num_trials_to_show, 3*num_trials_to_show+k);
    plot(ctx_t, mean_ctx_trace, 'k');
    hold on;
    plot(str_t, mean_d1_trace, 'r');
    plot(str_t, mean_d2_trace, 'b');
    plot_vertical_lines([trial.start_time, trial.us_time], a_lims, 'b:');
    plot_vertical_lines(trial.motion.onsets, a_lims, 'r:');
    hold off;
    xlim(t_lims);
    ylim(a_lims);
    if k == 1
        ylabel('Pop. mean spike rate (Hz)');
    else
%         set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    sp(5, num_trials_to_show, 4*num_trials_to_show+k);
    yyaxis left;
    plot(trial.velocity(:,1), trial.velocity(:,2));
    hold on;
    plot(t_lims, [0 0], 'k:');
    hold off;
    ylim(v_lims);
    if k == 1
        ylabel('Velocity (cm/s)');
    else
        set(gca, 'YTick', []);
    end
    yyaxis right;
    plot(trial.position(:,1), trial.position(:,2));
    hold on;
    plot_vertical_lines([trial.start_time, trial.us_time], p_lims, 'b:');
    plot_vertical_lines(trial.motion.onsets, p_lims, 'r:');
    plot(trial.lick_times, 0.95*p_lims(2)*ones(size(trial.lick_times)), 'b.');
    hold off;
    xlim(t_lims);
    ylim(p_lims);
    if k == num_trials_to_show
        ylabel('Encoder position');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'TickLength', [0 0]);
    xlabel('Time (s)');
    
end

end % show_ctxstr_trials

function frames_in_trial = find_frames_in_trial(t, t_trial)

frames_in_trial = find((t > t_trial(1)) & (t < t_trial(2)));

end % find_frames_in_trial