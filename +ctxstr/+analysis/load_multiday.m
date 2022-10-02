clear all;

load('all_matches.mat');
num_sessions = length(session_names);

sessions_to_track = [1 2 3 5 7 8];

%%

% Note that cross-day matches in 'all_matches.mat' are always computed with
% respect to all available datasets (see ctxstr.analysis.match_all_days).
% To match this convention, we preallocate ds arrays for all available
% datasets, but load in only those specified in 'sessions_to_track' (e.g.
% those with identified ST trials).

ds_ctx = cell(num_sessions,1);
for k = 1:num_sessions
    if ismember(k, sessions_to_track)
        ds_ctx{k} = DaySummary(...
            fullfile(session_names{k}, 'ctx/ctx-st_15hz.txt'),...
            fullfile(session_names{k}, 'ctx/union_15hz/dff'),...
            'cascade');
    end
end

ds_str = cell(num_sessions,1);
for k = 1:num_sessions
    if ismember(k, sessions_to_track)
        ds_str{k} = DaySummary(...
            fullfile(session_names{k}, 'str/str-st_15hz.txt'),...
            fullfile(session_names{k}, 'str/union_15hz/dff'),...
            'cascade');
    end
end

%%

region = 'ctx';
md = ctxstr.core.generate_md(ds_ctx, ctx_matches, sessions_to_track);

%%

region = 'str';
md = ctxstr.core.generate_md(ds_str, str_matches, sessions_to_track);

%% Visualization #1: Plot tracked cell rasters across days

raster_fns = {@(ds,k) ctxstr.vis.plot_raster_from_ds(ds, k, 2),...
              @(ds,k) ctxstr.vis.plot_raster_from_ds(ds, k, 3)};
         
for k = 1:md.num_cells
    draw_md_cell(md, k, raster_fns);
    drawnow;
    
    filename = sprintf('%s-%s_md%03d.png', mouse_name, region, k);
    print('-dpng', filename);
end