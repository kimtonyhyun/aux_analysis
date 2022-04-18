%% Load behavioral and neural data

clear all;

dataset_name = dirname;

session = load('ctxstr.mat');
trials = ctxstr.load_trials;

% Note that 'trials' includes all behavioral trials in the Saleae record,
% even those that are not captured by imaging. The subset of trials with
% imaging are in 'session.info.imaged_trials'
num_all_trials = length(trials);
num_imaged_trials = length(session.info.imaged_trials);
cprintf('blue', '* * * %s: Contains %d imaged trials * * *\n', dataset_name, num_imaged_trials);

% "Stereotypical" trials
st_trial_inds = ctxstr.behavior.find_stereotypical_trials(trials);
st_trial_inds = intersect(st_trial_inds, session.info.imaged_trials);

fps = 15;
path_to_ctx = 'ctx/union_15hz/dff';
path_to_str = 'str/union_15hz/dff';

[ctx.traces, ctx_info] = ctxstr.load_cascade_traces(path_to_ctx, fps);
ctx.t = ctxstr.core.bin_frame_times(session.ctx.frame_times, 2); % Assume ctx data temporally binned by factor 2
num_ctx_cells = size(ctx.traces, 1);

[str.traces, str_info] = ctxstr.load_cascade_traces(path_to_str, fps);
str.t = ctxstr.core.bin_frame_times(session.str.frame_times, 3);
num_str_cells = size(str.traces, 1);

% Load the behavior video, if available
vid_filename = get_most_recent_file('.', '*.mp4');
if ~isempty(vid_filename)
    vid = VideoReader(vid_filename);
end

%% Omit trials for grooming, etc.

omitted_trials = [28]; % e.g. grooming trials

st_trial_inds = setdiff(st_trial_inds, omitted_trials);
cprintf('blue', 'Found %d stereotyped trials out of %d imaged trials total\n',...
    length(st_trial_inds), num_imaged_trials);

% Compute appropriate ylims given this set of trials
ctx_max = 0; ctx_max_trial_idx = 0;
str_max = 0; str_max_trial_idx = 0;
for trial_idx = st_trial_inds
    trial = trials(trial_idx);
    trial_times = [trial.start_time trial.us_time]; % No padding
    
    ctx_traces = ctxstr.core.get_traces_by_time(ctx, trial_times);
    max_pop_ctx_trace = max(sum(ctx_traces, 1));
    if max_pop_ctx_trace > ctx_max
        ctx_max = max_pop_ctx_trace;
        ctx_max_trial_idx = trial_idx;
    end
    
    str_traces = ctxstr.core.get_traces_by_time(str, trial_times);
    max_pop_str_trace = max(sum(str_traces, 1));
    if max_pop_str_trace > str_max
        str_max = max_pop_str_trace;
        str_max_trial_idx = trial_idx;
    end
end
fprintf('  Maximum ctx activity occurs on Trial %d\n', ctx_max_trial_idx);
fprintf('  Maximum str activity occurs on Trial %d\n', str_max_trial_idx);
clear ctx_frames ctx_traces max_pop_ctx_trace str_frames str_traces max_pop_str_trace ctx_max_trial_idx str_max_trial_idx

%% Visualization #1: "Trial view"

% trials_to_show = session.info.imaged_trials;
% ctx_max = [];
% str_max = [];

trials_to_show = st_trial_inds;

num_trials_per_page = 8;
num_trials_to_show = length(trials_to_show);

trial_chunks = make_frame_chunks(num_trials_to_show, num_trials_per_page);
num_pages = size(trial_chunks, 1);

for k = 1:num_pages
    trials_to_show_k = trials_to_show(trial_chunks(k,1):trial_chunks(k,2));
    
    clf;
    ctxstr.vis.show_trials(trials_to_show_k, session, trials, ctx, str,...
        'name', dataset_name, 'ctx_max', ctx_max, 'str_max', str_max);
    
%     if ~isempty(str_info.tdt)
%         ctxstr.vis.show_ctxstr_tdt(trials_to_show, session, trials, ctx, str, str_info.tdt);
%     else
%         ctxstr.vis.show_ctxstr(trials_to_show, session, trials, ctx, str, 'name', dataset_name);
%     end
    
    fprintf('Page %d/%d: Showing Trials %d to %d...\n', k, num_pages,...
        trials_to_show_k(1), trials_to_show_k(end));
    
%     print('-dpng', sprintf('%s_st-trials_pg%02d.png', dataset_name, k));
    pause;
end

%% Visualization #2: Ctx single-cell rasters

for k = 1:num_ctx_cells
    ctxstr.vis.show_aligned_raster(k, st_trial_inds, trials, ctx);
    cell_id_in_rec = ctx_info.cell_ids_in_rec(k);
    title(sprintf('%s-ctx, cell #=%d (%s)', dataset_name, cell_id_in_rec, ctx_info.rec_name),...
          'Interpreter', 'None');
      
    print('-dpng', sprintf('%s-ctx_cell-%03d_raster.png', dataset_name, k));
%     pause;
end

%% Visualization #3: Str single-cell rasters

for k = 1:num_str_cells
    ctxstr.vis.show_aligned_raster(k, st_trial_inds, trials, str);
    cell_id_in_rec = str_info.cell_ids_in_rec(k);
    title(sprintf('%s-str, cell #=%d (%s)', dataset_name, cell_id_in_rec, str_info.rec_name),...
          'Interpreter', 'None');
      
    print('-dpng', sprintf('%s-str_cell-%03d_raster.png', dataset_name, k));
%     pause;
end

%% Visualization #4: Show basic behavior + some neurons (WIP)

sp = @(m,n,p) subtightplot(m, n, p, [0.01 0.05], 0.04, 0.04); % Gap, Margin-X, Margin-Y

trials_to_show = st_trial_inds;
ctx_inds_to_show = [11 15 18];
str_inds_to_show = [12 22 28];

num_ctx_to_show = length(ctx_inds_to_show);
num_str_to_show = length(str_inds_to_show);

num_rows = 1+num_ctx_to_show+num_str_to_show;
h_axes = zeros(num_rows, 1);

clf;
h_axes(1) = sp(num_rows,1,1);
yyaxis left;
hold on;
for k = trials_to_show
    vel = trials(k).velocity;
    plot(vel(:,1), vel(:,2), '-');
end
hold off;
ylim([-5 45]);
ylabel('Velocity (cm/s)');
yyaxis right;
y_lims = [0 session.behavior.position.us_threshold];
hold on;
for k = trials_to_show
    trial = trials(k);
    
    plot(trial.position(:,1), trial.position(:,2), '-');
    plot(trial.lick_times, 0.95*y_lims(2)*ones(size(trial.lick_times)), 'b.');
    
    plot_vertical_lines([trial.start_time trial.us_time], y_lims, 'b:');
    plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
end
ylim(y_lims);
ylabel('Position');
set(gca, 'TickLength', [0 0]);
title(dataset_name);

y_lims = [-0.15 1.15];
for i = 1:num_ctx_to_show
    h_axes(1+i) = sp(num_rows, 1, 1+i);
    ctx_idx = ctx_inds_to_show(i);
    
    hold on;
    for k = trials_to_show
        trial = trials(k);
        trial_time = [trial.start_time trial.us_time];
    
        [ctx_traces_k, ctx_times_k] = ctxstr.core.get_traces_by_time(ctx, trial_time);
        plot(ctx_times_k, ctx_traces_k(ctx_idx,:), 'k-');
    
        plot_vertical_lines([trial.start_time trial.us_time], y_lims, 'b:');
        plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
    end
    hold off;
    ylim(y_lims);
    ylabel(sprintf('Ctx cell #=%d', ctx_idx));
end

for j = 1:num_str_to_show
    h_axes(1+num_ctx_to_show+j) = sp(num_rows, 1, 1+num_ctx_to_show+j);
    str_idx = str_inds_to_show(j);
    
    hold on;
    for k = trials_to_show
        trial = trials(k);
        trial_time = [trial.start_time trial.us_time];
    
        [str_traces_k, str_times_k] = ctxstr.core.get_traces_by_time(str, trial_time);
        plot(str_times_k, str_traces_k(str_idx,:), 'm-');
    
        plot_vertical_lines([trial.start_time trial.us_time], y_lims, 'b:');
        plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
    end
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