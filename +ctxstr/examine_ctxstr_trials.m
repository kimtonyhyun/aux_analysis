clear all;

dataset_name = dirname;

session = load('ctxstr.mat');
trials = ctxstr.load_trials;

% Note that 'trials' includes all behavioral trials in the Saleae record,
% even those that are not captured by imaging. The subset of trials with
% imaging are in 'session.info.imaged_trials'
trials_to_show = session.info.imaged_trials; %#ok<NASGU>
num_imaged_trials = length(session.info.imaged_trials);
cprintf('blue', '* * * %s: Contains %d imaged trials * * *\n', dataset_name, num_imaged_trials);

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

%% Select trials with "stereotyped" movements

omitted_trials = [28]; % e.g. grooming trials

% A trial is "stereotypical" if it contains:
%   - Reward-delivery-timed licking at the beginning and end of trial;
%   - At least one motion onset
trials_to_show = zeros(1, num_imaged_trials);
idx = 0;
for k = 1:num_imaged_trials
    trial_idx = session.info.imaged_trials(k);
    trial =  trials(trial_idx);
    prev_trial = trials(trial_idx-1);
    
    if prev_trial.lick_response && trial.lick_response && ~isempty(trial.motion.onsets)
        idx = idx + 1;
        trials_to_show(idx) = trial_idx;
    end
end
trials_to_show = trials_to_show(1:idx);
clear idx;

trials_to_show = setdiff(trials_to_show, omitted_trials);
cprintf('blue', 'Found %d stereotyped trials out of %d imaged trials total\n',...
    length(trials_to_show), num_imaged_trials);

% Compute appropriate ylims given this set of trials
ctx_max = 0; ctx_max_trial_idx = 0;
str_max = 0; str_max_trial_idx = 0;
for trial_idx = trials_to_show
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

%% Plot MO-triggered velocity profiles for stereotypical trials

sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y
sp(4,2,8);
cla;
hold on;
for trial_idx = trials_to_show
    trial = trials(trial_idx);
    t = trial.velocity(:,1) - trial.motion.onsets(1);
%     plot(t, trial.velocity(:,2), 'Color', 0.7*[1 1 1]);
    plot(t, trial.velocity(:,2));
end
hold off;
xlim([-1 4]);
xlabel('Time after motion onset (s)');
% ylabel('Velocity (cm/s)');
title(dataset_name);
grid on;

%% Compute correlations

corrs = zeros(num_ctx_cells, num_str_cells);
for i = 1:num_ctx_cells % i-th ctx cell
    fprintf('%s: Computing correlations for ctx cell=%d...\n', datestr(now), i);
    for j = 1:num_str_cells % j-th str cell
        c = 0;
        clf;
        hold on;
        for k = trials_to_show % k-th trial
            trial = trials(k);
            trial_time = [trial.start_time, trial.us_time];
            
            % Retrieve the ctx and str traces, at their original sampling
            [ctx_frames_k, ctx_times_k] = ctxstr.core.find_frames_by_time(ctx.t, trial_time);
            ctx_tr_i = ctx.traces(i, ctx_frames_k);
            
            [str_frames_k, str_times_k] = ctxstr.core.find_frames_by_time(str.t, trial_time);
            str_tr_j = str.traces(j, str_frames_k);
            
            % Resample ctx and str traces for a common timebase
            t_lims = [max([ctx_times_k(1) str_times_k(1)]) min([ctx_times_k(end) str_times_k(end)])];
            num_samples = ceil(diff(t_lims) * 15); % At least 15 samples per s
            t_common = linspace(t_lims(1), t_lims(2), num_samples);
            
            ctx_tr_i_resampled = interp1(ctx_times_k, ctx_tr_i, t_common, 'linear');
            str_tr_j_resampled = interp1(str_times_k, str_tr_j, t_common, 'linear');
            
            p = sum(ctx_tr_i_resampled .* str_tr_j_resampled);
            if ~isnan(p)
                c = c + p;
            else
                cprintf('blue', 'Warning: Found NaN on Trial %d\n', k);
            end
            
            % Debug: Show plot
            plot(t_common, ctx_tr_i_resampled, 'b');
            plot(t_common, str_tr_j_resampled, 'r');            
        end
        corrs(i,j) = c;
        hold off;
        
        xlabel('Time (s)');
        ylabel('Trace (norm)');
        title(sprintf('Ctx cell=%d, Str cell=%d, corr=%.4f', i, j, c));
        pause;
    end
end

%%

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
    ctxstr.vis.show_aligned_raster(k, trials_to_show, trials, ctx);
    cell_id_in_rec = ctx_info.cell_ids_in_rec(k);
    title(sprintf('%s-ctx, cell #=%d (%s)', dataset_name, cell_id_in_rec, ctx_info.rec_name),...
          'Interpreter', 'None');
    pause;
end

%% Str

for k = 1:num_str_cells
    ctxstr.vis.show_aligned_raster(k, trials_to_show, trials, str);
    cell_id_in_rec = str_info.cell_ids_in_rec(k);
    title(sprintf('%s-str, cell #=%d (%s)', dataset_name, cell_id_in_rec, str_info.rec_name),...
          'Interpreter', 'None');
    pause;
end