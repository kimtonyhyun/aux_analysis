function show_ctxstr_tdt(trials_to_show, session, trials, ctx, str, tdt)

num_trials_to_show = length(trials_to_show);

num_ctx_cells = size(ctx.traces,1);
num_d1_cells = length(tdt.pos);
num_d2_cells = length(tdt.neg);

sp = @(m,n,p) subtightplot(m, n, p, 0.01, [0.04 0.025], 0.02); % Gap, Margin-X, Margin-Y

p_lims = [-50 session.behavior.position.us_threshold]; % Y-scale for encoder position
v_lims = [-5 max(session.behavior.velocity(:,2))];

% Compute Y-scale for mean pop. activity
ctx_max = max(mean(ctx.traces, 1));
d1_max = max(mean(str.traces(tdt.pos,:),1));
d2_max = max(mean(str.traces(tdt.neg,:),1));
ctx_a_lims = [0 1.1*ctx_max];
str_a_lims = [0 1.1*max([d1_max d2_max])];

v_color = [0 0.4470 0.7410];

for k = 1:num_trials_to_show
    trial_idx = trials_to_show(k);
    trial = trials(trial_idx);
    
    t_lims = trial.times; % Includes trial padding
    
    ctx_frames = ctxstr.find_frames_in_trial(ctx.t, t_lims);
    ctx_t = ctx.t(ctx_frames);
    ctx_traces = ctx.traces(:,ctx_frames);
    mean_ctx_trace = mean(ctx_traces, 1);    
       
    str_frames = ctxstr.find_frames_in_trial(str.t, t_lims);
    str_t = str.t(str_frames);
    str_traces = str.traces(:, str_frames);
    d1_traces = str_traces(tdt.pos, :);
    d2_traces = str_traces(tdt.neg, :);
    mean_d1_trace = mean(d1_traces, 1);
    mean_d2_trace = mean(d2_traces, 1);
    
    % Test: Try sorting cells by activation order
%     ctx_traces = sort_raster(ctx_traces);
%     d1_traces = sort_raster(d1_traces);
%     d2_traces = sort_raster(d2_traces);

    % Plots: 1) Velocity and position
    %------------------------------------------------------------
    ax1 = sp(5, num_trials_to_show, k);
    title(sprintf('Trial %d (%.1f s)', trial_idx, trial.duration));
    yyaxis left;
    plot(trial.velocity(:,1), trial.velocity(:,2));
    hold on;
    plot(t_lims, [0 0], '--', 'Color', v_color);
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
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    % 2) Population mean spike rates
    %------------------------------------------------------------
    ax2 = sp(5, num_trials_to_show, num_trials_to_show+k);
    yyaxis left;
    plot(ctx_t, mean_ctx_trace, 'k');
    ylim(ctx_a_lims);
    if k == 1
        ylabel('Ctx pop. mean spike rate (Hz)');
    else
        set(gca, 'YTick', []);
    end
    yyaxis right;
    plot(str_t, mean_d1_trace, 'r-');
    hold on;
    plot(str_t, mean_d2_trace, 'b-');
    ylim(str_a_lims);
    plot_vertical_lines([trial.start_time, trial.us_time], str_a_lims, 'b:');
    plot_vertical_lines(trial.motion.onsets, str_a_lims, 'r:');
    plot(trial.lick_times, 0.95*str_a_lims(2)*ones(size(trial.lick_times)), 'b.');
    hold off;
    xlim(t_lims);
    if k == num_trials_to_show
        ylabel('Str pop. mean spike rate (Hz)');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    % 3) Ctx raster
    %------------------------------------------------------------
    ax3 = sp(5, num_trials_to_show, 2*num_trials_to_show + k);
    imagesc(ctx_t, 1:num_ctx_cells, ctx_traces);
    hold on;
    plot_vertical_lines([trial.start_time, trial.us_time], [1 num_ctx_cells], 'w:');
    plot_vertical_lines(trial.motion.onsets, [1 num_ctx_cells], 'w:');
    hold off;
    xlim(t_lims);
    if k == 1
        ylabel('Ctx');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    % 4) D1 raster
    %------------------------------------------------------------
    ax4 = sp(5, num_trials_to_show, 3*num_trials_to_show+k);
    imagesc(str_t, 1:num_d1_cells, d1_traces); hold on;
    hold on;
    plot_vertical_lines([trial.start_time, trial.us_time], [1 num_d1_cells], 'w:');
    plot_vertical_lines(trial.motion.onsets, [1 num_d1_cells], 'w:');
    hold off;
    xlim(t_lims);
    if k == 1
        ylabel('Str (tdt-pos)');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    % 5) D2 raster
    %------------------------------------------------------------
    ax5 = sp(5, num_trials_to_show, 4*num_trials_to_show+k);
    imagesc(str_t, 1:num_d2_cells, d2_traces); hold on;
    hold on;
    plot_vertical_lines([trial.start_time, trial.us_time], [1 num_d2_cells], 'w:');
    plot_vertical_lines(trial.motion.onsets, [1 num_d2_cells], 'w:');
    hold off;
    xlim(t_lims);
    if k == 1
        ylabel('Str (tdt-neg)');
    else
        set(gca, 'YTick', []);
    end
    xlabel('Time (s)');
    set(gca, 'TickLength', [0 0]);
    
    linkaxes([ax1 ax2 ax3 ax4 ax5], 'x');
    zoom xon;
end

end % show_ctxstr_trials

function sorted_raster = sort_raster(raster)
    [~, max_frame] = max(raster,[],2);
    [~, order] = sort(max_frame, 'ascend');
    sorted_raster = raster(order,:);
end