clear all; close all;

%% Load data
% DCIMG files can be converted using:
%   convert_dcimg('m5R1_d200911_s09_1p00001.dcimg');
dataset_name = dirname;

filename_1p = get_most_recent_file('', '*.hdf5');
filename_2p = get_most_recent_file('', '*.tif');

M_2p = load_scanimage_tif(filename_2p);

%%

F_1p = compute_fluorescence_stats(filename_1p);
F_2p = compute_fluorescence_stats(M_2p);

ax1 = subplot(211);
plot(F_1p);
grid on;
title(filename_1p, 'Interpreter', 'none');
ax2 = subplot(212);
plot(F_2p);
grid on;
title(filename_2p, 'Interpreter', 'none');
linkaxes([ax1 ax2], 'x');
xlim([0 1000]);

%% Decide number of frames to chop

max_frames = min(size(F_1p,1), size(F_2p,1)); % Sometimes there is 1 extra frame
keep_frames = 201:max_frames;

M_1p = load_movie_from_hdf5(filename_1p, keep_frames([1 end]));
M_2p = M_2p(:,:,keep_frames);

%% Crop the 2P movie, to remove chopper and other edge effects

% view_movie(M_2p, 'clim', [0 6000]);

horiz_trim = 15;
keep_cols_2p = (1+horiz_trim):(size(M_2p,2)-horiz_trim);
keep_rows_2p = 75:425;

M_2p = M_2p(keep_rows_2p, keep_cols_2p, :);

% Rescale 2P zero
F_2p_chopped = compute_fluorescence_stats(M_2p);
M_2p = M_2p - int16(mean(F_2p_chopped(:,1)));

%% Save data

savename_1p = sprintf('%s-1P.hdf5', dataset_name);
savename_2p = sprintf('%s-2P.hdf5', dataset_name);

save_movie_to_hdf5(M_1p, savename_1p);
save_movie_to_hdf5(M_2p, savename_2p);

save('preproc_1p2p', 'dataset_name', 'keep_frames', 'keep_cols_2p', 'keep_rows_2p');

% Move files to subdirectory
mkdir('1P');
movefile(savename_1p, '1P');
mkdir('2P');
movefile(savename_2p, '2P');

%% Splitting up multi-plane 2P data

movie_filename = get_most_recent_file('', '*.hdf5');
M0 = load_movie(movie_filename);

[~, movie_stem] = fileparts(movie_filename);

num_planes = 6;
M = cell(num_planes,1);
for k = 1:num_planes
    M_k = M0(:,:,k:num_planes:end);
    F_k = compute_fluorescence_stats(M_k);
    M_k = M_k - int16(mean(F_k(:,1)));
    
    sl_dirname = sprintf('sl%d', k);
    mkdir(sl_dirname);   
    sl_name = sprintf('%s/%s-sl%d.hdf5', sl_dirname, movie_stem, k);
    save_movie_to_hdf5(M_k, sl_name);
end

%% Cell extraction: EXTRACT

% 1P: Prior to cell extraction, run:
%   - Motion correction (TurboReg)
%   - Cropping (for motion correction edge artifacts)
%   - Norm movie by Miji
%   - DFF movie
%
% 2P:
%   - Mean correction
%   - NormCorre
%   - zscore movie

movie_filename = get_most_recent_file('', '*.hdf5');
cprintf('Blue', '%s: Running EXTRACT on "%s"...\n', datestr(now), movie_filename);

config = get_defaults([]);
config.preprocess = 0;
config.remove_stationary_baseline = 0;
config.cellfind_filter_type = 'none';
config.cellfind_min_snr = 1;

switch dirname
    case '1P'
        config.num_partitions_x = 1;
        config.num_partitions_y = 1;
        config.avg_cell_radius = 10;
        
    otherwise % Assume 2P
        config.num_partitions_x = 1;
        config.num_partitions_y = 1;
        config.avg_cell_radius = 10;
end


%%
output = extractor(sprintf('%s:/Data/Images', movie_filename), config);
cprintf('Blue', 'Done with EXTRACT. Found %d cells in %.1f min\n',...
    size(output.spatial_weights, 3), output.info.runtime / 60);
ext_filename = import_extract(output);

mkdir('ext1/orig');
movefile(ext_filename, 'ext1/orig');

%% CELLMax

movie_filename = get_most_recent_file('', '*.hdf5');

cellmax.loadRepoFunctions;
options.CELLMaxoptions.maxSqSize = 250;
options.CELLMaxoptions.sqOverlap = 50;
options.eventOptions.framerate = 26;

cprintf('Blue', '%s: Running CELLMax...\n', datestr(now));
output = cellmax.runCELLMax(movie_filename, 'options', options);
cprintf('Blue', 'Done with CELLMax. Found %d cells in %.1f min\n',...
    size(output.cellImages, 3), output.runtime / 60);
cm_filename = import_cellmax(output);

mkdir('cm1/orig');
movefile(cm_filename, 'cm1/orig');

%% Compare EXTRACT vs. CELLMax

clear all;

ds_cm = DaySummary('', 'cm1/proj');
ds_ext = DaySummary('', 'ext1/proj');

plot_boundaries_with_transform(ds_ext, 'b', 2);
hold on;
plot_boundaries_with_transform(ds_cm, 'r');
hold off;
title_str = sprintf('%s: EXTRACT (%d cells; blue) vs. CELLMax (%d cells; red)',...
    dirname(1), ds_ext.num_classified_cells, ds_cm.num_classified_cells);
title(title_str);
set(gca, 'FontSize', 18);

%% Merge EXTRACT and CELLMax

movie_filename = get_most_recent_file('', '*.hdf5');
M = load_movie(movie_filename);

md = create_merge_md([ds_ext ds_cm]);
res_list = resolve_merged_recs(md, M, 'norm_traces');
resolved_filename = save_resolved_recs(res_list, md);

mkdir('cm_ext1/orig');
movefile(resolved_filename, 'cm_ext1/orig');

ds = DaySummary([], 'cm_ext1/orig');
clearvars -except ds M;

classify_cells(ds, M);