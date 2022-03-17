clear all;

dataset_name = dirname;

session = load('ctxstr.mat');

% Note that 'trials' includes all behavioral trials in the Saleae record,
% even those that are not captured by imaging. The subset of trials with
% imaging are in 'session.info.imaged_trials'
trials = ctxstr.load_trials;

fps = 15;
path_to_ctx = 'ctx/union_15hz/dff';
path_to_str = 'str/union_15hz/dff';

ctx.traces = ctxstr.load_cascade_traces(path_to_ctx, fps);
ctx.t = ctxstr.core.bin_frame_times(session.ctx.frame_times, 2); % Assume ctx data temporally binned by factor 2
num_ctx_cells = size(ctx.traces, 1);

[str.traces, tdt] = ctxstr.load_cascade_traces(path_to_str, fps);
str.t = ctxstr.core.bin_frame_times(session.str.frame_times, 3);
num_str_cells = size(str.traces, 1);

%%

num_trials_per_page = 8;
num_imaged_trials = length(session.info.imaged_trials);

trial_chunks = make_frame_chunks(num_imaged_trials, num_trials_per_page);
num_pages = size(trial_chunks, 1);

for k = 1:num_pages
    trials_to_show = session.info.imaged_trials(trial_chunks(k,1):trial_chunks(k,2));
    
    if ~isempty(tdt)
        ctxstr.vis.show_ctxstr_tdt(trials_to_show, session, trials, ctx, str, tdt);
    else
        ctxstr.vis.show_ctxstr(trials_to_show, session, trials, ctx, str);
    end
    
    fprintf('Page %d/%d: Showing Trials %d to %d...\n', k, num_pages,...
        trials_to_show(1), trials_to_show(end));
    pause;
end

%% Ctx

for cell_idx = 1:num_ctx_cells
    ctxstr.vis.show_aligned_raster(cell_idx, session.info.imaged_trials, trials, ctx);
    title(sprintf('%s-ctx, cell=%d/%d', dataset_name, cell_idx, num_ctx_cells));
    pause;
end

%% Str

for cell_idx = 1:num_str_cells
    ctxstr.vis.show_aligned_raster(cell_idx, session.info.imaged_trials, trials, str);
    title(sprintf('%s-str, cell=%d/%d', dataset_name, cell_idx, num_str_cells));
    pause;
end