clear all;

dataset_name = dirname;
cprintf('blue', '* * * %s * * *\n', dataset_name);

% Load behavioral data
%------------------------------------------------------------
session = load('ctxstr.mat');
trials = ctxstr.load_trials(0); % No trial padding

% Note that 'trials' includes all behavioral trials in the Saleae record,
% even those that are not captured by imaging. The subset of trials with
% imaging are in 'session.info.imaged_trials'
num_all_trials = length(trials);
num_imaged_trials = length(session.info.imaged_trials);

% Find "Stereotypical" trials, defined by mouse behavior
st_trial_inds = ctxstr.behavior.find_stereotypical_trials(trials);
st_trial_inds = intersect(st_trial_inds, session.info.imaged_trials);

% Load imaging data
%------------------------------------------------------------
fps = 15;
path_to_ctx = 'ctx/union_15hz/dff';
path_to_str = 'str/union_15hz/dff';

[ctx_traces, ctx_info] = ctxstr.load_cascade_traces(path_to_ctx, fps);

% All data will be aligned to cortical imaging samples
t = ctxstr.core.bin_frame_times(session.ctx.frame_times, 2);

[str_traces_orig, str_info] = ctxstr.load_cascade_traces(path_to_str, fps);
str_times_orig = ctxstr.core.bin_frame_times(session.str.frame_times, 3);

% Resample the striatal traces to line up with cortex sampling times
str_traces = ctxstr.core.resample_traces(str_traces_orig, str_times_orig, t);

% Parse data into trials, and compute correlations
[ctx_traces_by_trial, time_by_trial] = ctxstr.core.parse_into_trials(ctx_traces, t, trials);
str_traces_by_trial = ctxstr.core.parse_into_trials(str_traces, t, trials);

% Load the behavior video, if available
% vid_filename = get_most_recent_file('.', '*.mp4');
% if ~isempty(vid_filename)
%     vid = VideoReader(vid_filename);
% end

%% Omit trials for grooming, etc., and filter out NaN's

omitted_trials = [9 258]; % e.g. grooming trials
st_trial_inds = setdiff(st_trial_inds, omitted_trials);

% Filter for NaN values, arising from CASCADE
for k = st_trial_inds
    if any(isnan(ctx_traces_by_trial{k}(:))) || any(isnan(str_traces_by_trial{k}(:)))
        st_trial_inds = setdiff(st_trial_inds, k);
        fprintf('Omitted Trial %d due to NaNs\n', k);
    end
end

fprintf('Found %d usable stereotyped trials out of %d imaged trials total\n',...
    length(st_trial_inds), num_imaged_trials);

%% Save data

save('resampled_data.mat', 'dataset_name', 'session',...
        'trials', 'st_trial_inds', ...
        't', 'fps', 'ctx_traces', 'ctx_info', 'str_traces', 'str_info',...
        'time_by_trial', 'ctx_traces_by_trial', 'str_traces_by_trial');

%% Visualization #1: "Trial view"

% Compute appropriate ylims given this set of trials
ctx_max = ctxstr.core.find_max_population_activity(ctx_traces_by_trial, st_trial_inds);
str_max = ctxstr.core.find_max_population_activity(str_traces_by_trial, st_trial_inds);

num_trials_per_page = 8;
num_trials_to_show = length(st_trial_inds);

trial_chunks = make_frame_chunks(num_trials_to_show, num_trials_per_page);
num_pages = size(trial_chunks, 1);

for k = 1:num_pages
    trials_to_show_k = st_trial_inds(trial_chunks(k,1):trial_chunks(k,2));
    
    clf;
    ctxstr.vis.show_trials(trials_to_show_k, session, trials,...
        t, ctx_traces, str_traces,...
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

ctx_dir = '_rasters-ctx';
mkdir(ctx_dir);

for k = 1:ctx_info.num_cells
    ctxstr.vis.show_aligned_raster(st_trial_inds, trials, ctx_traces(k,:), t);
    cell_id_in_rec = ctx_info.ind2rec(k);
    title(sprintf('%s-ctx, cell #=r%d (%s)', dataset_name, cell_id_in_rec, ctx_info.rec_name),...
          'Interpreter', 'None');
      
    drawnow;
    print('-dpng', fullfile(ctx_dir, sprintf('%s-ctx_cell-r%03d_raster.png', dataset_name, cell_id_in_rec)));
%     pause;
end

%% Visualization #3: Str single-cell rasters

str_dir = '_rasters-str';
mkdir(str_dir);

for k = 1:str_info.num_cells
    ctxstr.vis.show_aligned_raster(st_trial_inds, trials, str_traces(k,:), t);
    cell_id_in_rec = str_info.ind2rec(k);
    title(sprintf('%s-str, cell #=r%d (%s)', dataset_name, cell_id_in_rec, str_info.rec_name),...
          'Interpreter', 'None');
      
    drawnow;
    print('-dpng', fullfile(str_dir, sprintf('%s-str_cell-r%03d_raster.png', dataset_name, cell_id_in_rec)));
%     pause;
end
