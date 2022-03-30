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

omitted_trials = [92]; % e.g. grooming trials

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

%% Compute correlations

trials_to_use = st_trial_inds;

resampled_ctx_traces = cell(1, num_all_trials);
resampled_str_traces = cell(1, num_all_trials);
common_time = cell(1, num_all_trials);
for k = trials_to_use
    trial = trials(k);
    trial_time = [trial.start_time trial.us_time];
    
    [ctx_traces_k, ctx_times_k] = ctxstr.core.get_traces_by_time(ctx, trial_time);
    [str_traces_k, str_times_k] = ctxstr.core.get_traces_by_time(str, trial_time);
    
    if any(isnan(ctx_traces_k(:))) || any(isnan(str_traces_k(:)))
        trials_to_use = setdiff(trials_to_use, k);
        fprintf('Omitting Trial %d from correlation calculation due to NaNs\n', k);
    else
        [resampled_ctx_traces{k}, resampled_str_traces{k}, common_time{k}] = ctxstr.core.resample_ctxstr_traces(...
            ctx_traces_k, ctx_times_k, str_traces_k, str_times_k);
    end
end

% Method #1: Pearson correlation between traces
%------------------------------------------------------------
cont_ctx_traces = cell2mat(resampled_ctx_traces);
cont_str_traces = cell2mat(resampled_str_traces);
C_ctx = corr(cont_ctx_traces');
C_str = corr(cont_str_traces');
C_ctxstr = corr(cont_ctx_traces', cont_str_traces');

%% Display correlation matrix

figure;
imagesc(C_ctxstr);
axis image;
xlabel('Str neurons');
ylabel('Ctx neurons');
set(gca, 'FontSize', 18);
set(gca, 'TickLength', [0 0]);
colorbar;
title(sprintf('%s correlations', dataset_name));

%% Inspect pairs of single-trial ctxstr traces

% figure;
mode = 'ctxstr';

switch (mode)
    case 'ctxstr'
        corrlist = sortrows(corr_to_corrlist(C_ctxstr), 3, 'descend');
        get_trace1 = @(k,i) resampled_ctx_traces{k}(i,:); % i-th ctx cell on k-th trial
        get_trace2 = @(k,j) resampled_str_traces{k}(j,:); % i-th str cell on k-th trial
        get_ylabel = @(i,j,c) sprintf('Ctx=%d\nStr=%d\nCorr=%.4f',...
            ctx_info.cell_ids_in_rec(i), str_info.cell_ids_in_rec(j), c); % Report cell #'s as in the rec file
        
    case 'ctx'
        corrlist = sortrows(corr_to_corrlist(C_ctx, 'upper'), 3, 'descend');
        get_trace1 = @(k,i) resampled_ctx_traces{k}(i,:);
        get_trace2 = @(k,j) resampled_ctx_traces{k}(j,:);
        get_ylabel = @(i,j,c) sprintf('Ctx=%d\nCtx=%d\nCorr=%.4f',...
            ctx_info.cell_ids_in_rec(i), ctx_info.cell_ids_in_rec(j), c);
        
    case 'str'
        corrlist = sortrows(corr_to_corrlist(C_str, 'upper'), 3, 'descend');
        get_trace1 = @(k,i) resampled_str_traces{k}(i,:);
        get_trace2 = @(k,j) resampled_str_traces{k}(j,:);
        get_ylabel = @(i,j,c) sprintf('Str=%d\nStr=%d\nCorr=%.4f',...
            str_info.cell_ids_in_rec(i), str_info.cell_ids_in_rec(j), c);
        
end

num_to_show = 8;
sp = @(m,n,p) subtightplot(m, n, p, [0.02 0.05], 0.04, 0.03); % Gap, Margin-X, Margin-Y

trial_start_times = [trials(trials_to_use).start_time];
t_lims = [trials(trials_to_use(1)).start_time trials(trials_to_use(end)).us_time];

clf;
for i = 1:num_to_show
    cell_idx1 = corrlist(i,1);
    cell_idx2 = corrlist(i,2);
    corr_val = corrlist(i,3);
    
    sp(num_to_show,1,i);
    hold on;
    for k = trials_to_use
        trial = trials(k);

        plot(common_time{k}, get_trace1(k, cell_idx1), 'k');
        plot(common_time{k}, get_trace2(k, cell_idx2), 'm');
        plot_vertical_lines([trial.start_time, trial.us_time], [0 1], 'b:');
        plot_vertical_lines(trial.motion.onsets, [0 1], 'r:');
    end
    hold off;
    ylim([0 1]);
    xlim(t_lims);
       
    ylabel(get_ylabel(cell_idx1, cell_idx2, corr_val));
    zoom xon;
    set(gca, 'TickLength', [0 0]);
    set(gca, 'XTick', trial_start_times);
    set(gca, 'XTickLabel', trials_to_use);
    if (i == 1)
        title(sprintf('%s - Top %d correlated %s pairs',...
            dataset_name, num_to_show, upper(mode)));
    elseif (i == num_to_show)
        xlabel('Trial index');
    end
end


%%

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

%% Ctx

for k = 1:num_ctx_cells
    ctxstr.vis.show_aligned_raster(k, st_trial_inds, trials, ctx);
    cell_id_in_rec = ctx_info.cell_ids_in_rec(k);
    title(sprintf('%s-ctx, cell #=%d (%s)', dataset_name, cell_id_in_rec, ctx_info.rec_name),...
          'Interpreter', 'None');
    pause;
end

%% Str

for k = 1:num_str_cells
    ctxstr.vis.show_aligned_raster(k, st_trial_inds, trials, str);
    cell_id_in_rec = str_info.cell_ids_in_rec(k);
    title(sprintf('%s-str, cell #=%d (%s)', dataset_name, cell_id_in_rec, str_info.rec_name),...
          'Interpreter', 'None');
    pause;
end