function show_trials(trials_to_show, session, trials, ctx, str, varargin)

% Defaults
dataset_name = '';
ctx_max = []; % Determines ylim for displaying neural activity traces
str_max = [];

for k = 1:length(varargin)
    if ischar(varargin{k})
        switch lower(varargin{k})
            case {'dataset_name', 'name'}
                dataset_name = varargin{k+1};
            case 'ctx_max'
                ctx_max = varargin{k+1};
            case 'str_max'
                str_max = varargin{k+1};
        end
    end
end

num_trials_to_show = length(trials_to_show);

num_ctx_cells = size(ctx.traces,1);
num_str_cells = size(str.traces,1);

sp = @(m,n,p) subtightplot(m, n, p, 0.01, [0.04 0.025], 0.02); % Gap, Margin-X, Margin-Y

p_lims = [-50 session.behavior.position.us_threshold]; % Y-scale for encoder position
v_lims = [-5 max(session.behavior.velocity(:,2))];

% If not externally provided, calculate appropriate ylim for mean pop. activity
if isempty(ctx_max)
    ctx_max = max(sum(ctx.traces, 1));
end
if isempty(str_max)
    ctx_max = max(sum(str.traces, 1));
end
ctx_a_lims = [0 1.1*ctx_max];
str_a_lims = [0 1.1*str_max];

v_color = [0 0.4470 0.7410];

num_subplot_columns = max(8, num_trials_to_show);

for k = 1:num_trials_to_show
    trial_idx = trials_to_show(k);
    trial = trials(trial_idx);
    
    t_lims = trial.times; % Includes trial padding
    
    [ctx_traces, ctx_t] = ctxstr.core.get_traces_by_time(ctx, t_lims);
    pop_ctx_trace = sum(ctx_traces, 1);
       
    [str_traces, str_t] = ctxstr.core.get_traces_by_time(str, t_lims);
    pop_str_trace = sum(str_traces, 1);

    % Plots: 1) Velocity and position
    %------------------------------------------------------------
    ax1 = sp(4, num_subplot_columns, k);
    if ~isempty(dataset_name) && (k == 1)
        title(sprintf('%s, Trial %d (%.1f s)', dataset_name, trial_idx, trial.duration));
    else
        title(sprintf('Trial %d (%.1f s)', trial_idx, trial.duration));
    end
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
    ax2 = sp(4, num_subplot_columns, num_subplot_columns+k);
    yyaxis left;
    plot(ctx_t, pop_ctx_trace, 'k');
    ylim(ctx_a_lims);
    if k == 1
        ylabel('Ctx pop. activity');
    else
        set(gca, 'YTick', []);
    end
    yyaxis right;
    plot(str_t, pop_str_trace, 'm-');
    hold on;
    ylim(str_a_lims);
    plot_vertical_lines([trial.start_time, trial.us_time], str_a_lims, 'b:');
    plot_vertical_lines(trial.motion.onsets, str_a_lims, 'r:');
    plot(trial.lick_times, 0.95*str_a_lims(2)*ones(size(trial.lick_times)), 'b.');
    hold off;
    xlim(t_lims);
    if k == num_trials_to_show
        ylabel('Str pop. activity');
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    % 3) Ctx raster
    %------------------------------------------------------------
    ax3 = sp(4, num_subplot_columns, 2*num_subplot_columns + k);
    imagesc(ctx_t, 1:num_ctx_cells, ctx_traces);
    hold on;
    plot_vertical_lines([trial.start_time, trial.us_time], [1 num_ctx_cells], 'w:');
    plot_vertical_lines(trial.motion.onsets, [1 num_ctx_cells], 'w:');
    hold off;
    xlim(t_lims);
    if k == 1
        ylabel(sprintf('Ctx neurons (%d total)', num_ctx_cells));
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'XTick', []);
    set(gca, 'TickLength', [0 0]);
    
    % 4) Str raster
    %------------------------------------------------------------
    ax4 = sp(4, num_subplot_columns, 3*num_subplot_columns+k);
    imagesc(str_t, 1:num_str_cells, str_traces); hold on;
    hold on;
    plot_vertical_lines([trial.start_time, trial.us_time], [1 num_str_cells], 'w:');
    plot_vertical_lines(trial.motion.onsets, [1 num_str_cells], 'w:');
    hold off;
    xlim(t_lims);
    if k == 1
        ylabel(sprintf('Str neurons (%d total)', num_str_cells));
    else
        set(gca, 'YTick', []);
    end
    set(gca, 'TickLength', [0 0]);
    xlabel('Time (s)');
    
    linkaxes([ax1 ax2 ax3 ax4], 'x');
    zoom xon;
end

end % show_ctxstr_trials
