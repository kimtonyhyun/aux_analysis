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

[ctx.traces, ctx_info] = ctxstr.load_cascade_traces(path_to_ctx, fps);
ctx.t = ctxstr.core.bin_frame_times(session.ctx.frame_times, 2); % Assume ctx data temporally binned by factor 2
num_ctx_cells = size(ctx.traces, 1);

[str.traces, str_info] = ctxstr.load_cascade_traces(path_to_str, fps);
str.t = ctxstr.core.bin_frame_times(session.str.frame_times, 3);
num_str_cells = size(str.traces, 1);

%%

num_trials_per_page = 8;
num_imaged_trials = length(session.info.imaged_trials);

trial_chunks = make_frame_chunks(num_imaged_trials, num_trials_per_page);
num_pages = size(trial_chunks, 1);

for k = 1:num_pages
    trials_to_show = session.info.imaged_trials(trial_chunks(k,1):trial_chunks(k,2));
    
    if ~isempty(str_info.tdt)
        ctxstr.vis.show_ctxstr_tdt(trials_to_show, session, trials, ctx, str, str_info.tdt);
    else
        ctxstr.vis.show_ctxstr(trials_to_show, session, trials, ctx, str);
    end
    
    fprintf('Page %d/%d: Showing Trials %d to %d...\n', k, num_pages,...
        trials_to_show(1), trials_to_show(end));
    pause;
end

%% Ctx

for k = 1:num_ctx_cells
    ctxstr.vis.show_aligned_raster(k, session.info.imaged_trials, trials, ctx);
    cell_id_in_rec = ctx_info.cell_ids_in_rec(k);
    title(sprintf('%s-ctx, cell #=%d (%s)', dataset_name, cell_id_in_rec, ctx_info.rec_name),...
          'Interpreter', 'None');
    pause;
end

%% Str

for k = 1:num_str_cells
    ctxstr.vis.show_aligned_raster(k, session.info.imaged_trials, trials, str);
    cell_id_in_rec = str_info.cell_ids_in_rec(k);
    title(sprintf('%s-str, cell #=%d (%s)', dataset_name, cell_id_in_rec, str_info.rec_name),...
          'Interpreter', 'None');
    pause;
end