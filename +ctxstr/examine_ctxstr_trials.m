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

cdata = load(get_most_recent_file(path_to_ctx, 'cascade_*.mat'), 'spike_probs');
ctx.traces = fps * cdata.spike_probs'; % Convert to spike rates (Hz); [Cells x Time]
ctx.t = ctxstr.core.bin_frame_times(session.ctx.frame_times, 2); % Assume ctx data temporally binned by factor 2
num_ctx_cells = size(ctx.traces, 1);
clear cdata;

sdata = load(get_most_recent_file(path_to_str, 'cascade_*.mat'), 'spike_probs');
str.traces = fps * sdata.spike_probs';
str.t = ctxstr.core.bin_frame_times(session.str.frame_times, 3);
num_str_cells = size(str.traces, 1);
clear sdata;

tdt = load_tdt(path_to_str);

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

for cell_idx = 1:size(ctx.traces, 1)
    clf;
    [R_us, t_us, info_us] = ctxstr.core.compute_us_aligned_raster(cell_idx, session.info.imaged_trials, trials, ctx);
    [R_mo, t_mo, info_mo] = ctxstr.core.compute_mo_aligned_raster(cell_idx, session.info.imaged_trials, trials, ctx);

    ax1 = subplot(3,2,1);
    hold on;
    for k = 1:info_us.n
        plot(info_us.trial_times{k}, info_us.traces{k}, 'k-');
    end
    hold off;
    xlim(info_us.t_lims);
    title(sprintf('Ctx cell idx=%d out of %d', cell_idx, num_ctx_cells));

    ax2 = subplot(3,2,2);
    hold on;
    for k = 1:info_mo.n
        plot(info_mo.trial_times{k}, info_mo.traces{k}, 'k-');
    end
    hold off;
    xlim(info_mo.t_lims);

    ax3 = subplot(3,2,[3 5]);
    imAlpha = ones(size(R_us));
    imAlpha(isnan(R_us)) = 0;
    imagesc(t_us, 1:info_us.n, R_us, 'AlphaData', imAlpha);

    ax4 = subplot(3,2,[4 6]);
    imAlpha = ones(size(R_mo));
    imAlpha(isnan(R_mo)) = 0;
    imagesc(t_mo, 1:info_mo.n, R_mo, 'AlphaData', imAlpha);

    linkaxes([ax1 ax3], 'x');
    linkaxes([ax2 ax4], 'x');
    xlim(ax3, [-8 0]);
    xlim(ax4, [-3 5]);
    
    pause;
end

%% Str

for cell_idx = 1:size(str.traces, 1)
    clf;
    [R_us, t_us, info_us] = ctxstr.core.compute_us_aligned_raster(cell_idx, session.info.imaged_trials, trials, str);
    [R_mo, t_mo, info_mo] = ctxstr.core.compute_mo_aligned_raster(cell_idx, session.info.imaged_trials, trials, str);

    ax1 = subplot(3,2,1);
    hold on;
    for k = 1:info_us.n
        plot(info_us.trial_times{k}, info_us.traces{k}, 'k-');
    end
    hold off;
    xlim(info_us.t_lims);
    title(sprintf('Str cell idx=%d out of %d', cell_idx, num_str_cells));

    ax2 = subplot(3,2,2);
    hold on;
    for k = 1:info_mo.n
        plot(info_mo.trial_times{k}, info_mo.traces{k}, 'k-');
    end
    hold off;
    xlim(info_mo.t_lims);

    ax3 = subplot(3,2,[3 5]);
    imAlpha = ones(size(R_us));
    imAlpha(isnan(R_us)) = 0;
    imagesc(t_us, 1:info_us.n, R_us, 'AlphaData', imAlpha);

    ax4 = subplot(3,2,[4 6]);
    imAlpha = ones(size(R_mo));
    imAlpha(isnan(R_mo)) = 0;
    imagesc(t_mo, 1:info_mo.n, R_mo, 'AlphaData', imAlpha);

    linkaxes([ax1 ax3], 'x');
    linkaxes([ax2 ax4], 'x');
    xlim(ax3, [-8 0]);
    xlim(ax4, [-3 5]);
    
    pause;
end