clear all;

load('all_matches.mat');
num_sessions = length(session_names);

ds_ctx = cell(num_sessions,1);
for k = 1:num_sessions
        ds_ctx{k} = DaySummary(...
            fullfile(session_names{k}, 'ctx/ctx-st_15hz.txt'),...
            fullfile(session_names{k}, 'ctx/union_15hz/dff'),...
            'cascade');
end

ds_str = cell(num_sessions,1);
for k = 1:num_sessions
        ds_str{k} = DaySummary(...
            fullfile(session_names{k}, 'str/str-st_15hz.txt'),...
            fullfile(session_names{k}, 'str/union_15hz/dff'),...
            'cascade');
end

%%

region = 'ctx';
md = ctxstr.core.generate_md(ds_ctx, ctx_matches, 1:8);

%%

region = 'str';
md = ctxstr.core.generate_md(ds_str, str_matches, 1:8);

%% Visualization #1: Plot tracked cell rasters across days

align_to = 3;
raster_fn = @(ds,k) ctxstr.vis.plot_raster_from_ds(ds, k, align_to);
for k = 1:md.num_cells
    draw_md_cell(md, k, raster_fn);
    drawnow;
    switch align_to
        case 2
            filename = sprintf('%s-%s_md%03d_mo.png', mouse_name, region, k);
        case 3
            filename = sprintf('%s-%s_md%03d_us.png', mouse_name, region, k);
    end
    print('-dpng', filename);
end