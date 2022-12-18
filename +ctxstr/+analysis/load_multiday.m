clear all;

match_data = load('all_matches.mat');
num_sessions = length(match_data.session_names);

sessions_to_track = [1 2 4 5 6 7 8];

%%

% Note that cross-day matches in 'all_matches.mat' are always computed with
% respect to all available datasets (see ctxstr.analysis.match_all_days).
% To match this convention, we preallocate ds arrays for all available
% datasets, but load in only those specified in 'sessions_to_track' (e.g.
% those with identified ST trials).

bin_threshold = 0.2; % Binarization threshold for CASCADE traces

ds_ctx = cell(num_sessions,1);
for k = 1:num_sessions
    if ismember(k, sessions_to_track)
        session_name = match_data.session_names{k};
        ds_ctx{k} = DaySummary(...
            fullfile(session_name, 'ctx/ctx-st_15hz.txt'),...
            fullfile(session_name, 'ctx/union_15hz/dff'),...
            'cascade-bin', bin_threshold);
    end
end

ds_str = cell(num_sessions,1);
for k = 1:num_sessions
    if ismember(k, sessions_to_track)
        session_name = match_data.session_names{k};
        ds_str{k} = DaySummary(...
            fullfile(session_name, 'str/str-st_15hz.txt'),...
            fullfile(session_name, 'str/union_15hz/dff'),...
            'cascade-bin', bin_threshold);
    end
end

%%

brain_area = 'ctx';
match_type = 'full';
md = ctxstr.core.generate_md(ds_ctx, match_data.ctx_matches,...
        cellfun(@(x) sprintf('%s-ctx', x), match_data.session_names, 'UniformOutput', false),...
        sessions_to_track, 'match_type', match_type);

%%

brain_area = 'str';
match_type = 'link';
md = ctxstr.core.generate_md(ds_str, match_data.str_matches,...
    cellfun(@(x) sprintf('%s-str', x), match_data.session_names, 'UniformOutput', false),...
    sessions_to_track, 'match_type', match_type);

%% Visualization #1: Plot tracked cell rasters across days

raster_fns = {@(ds,k) ctxstr.vis.plot_raster_from_ds(ds, k, 2),...
              @(ds,k) ctxstr.vis.plot_raster_from_ds(ds, k, 3)};
         
for k = 1:md.num_cells
    draw_md_cell(md, k, raster_fns);
    drawnow;
    
%     filename = sprintf('%s-%s_md%03d_bin0-2.png', mouse_name, brain_area, k);
%     print('-dpng', filename);
    pause;
end