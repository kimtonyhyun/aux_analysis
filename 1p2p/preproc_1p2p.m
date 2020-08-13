clear all; close all;

%% Load data

dataset_name = dirname;

filename_1p = get_most_recent_file('', '*.h5');
filename_2p = get_most_recent_file('', '*.tif');

M_1p = h5read(filename_1p, '/1');
M_2p = load_scanimage_tif(filename_2p);

%%

F_1p = compute_fluorescence_stats(M_1p);
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

%% Decide number of frames to chop

keep_frames = 301:20000;

M_1p_chopped = M_1p(:,:,keep_frames);
M_2p_chopped = M_2p(:,:,keep_frames);

%% Crop the 2P movie, to remove chopper and other edge effects

% view_movie(M_2p_chopped, 'clim', [0 6000]);

horiz_trim = 20;
keep_cols_2p = (1+horiz_trim):(size(M_2p_chopped,2)-horiz_trim);
keep_rows_2p = 40:440;

M_2p_chopped = M_2p_chopped(keep_rows_2p, keep_cols_2p, :);

% Rescale 2P zero
F_2p_chopped = compute_fluorescence_stats(M_2p_chopped);
M_2p_chopped = M_2p_chopped - int16(mean(F_2p_chopped(:,1)));

%% Save data

savename_1p = sprintf('%s-1P.hdf5', dataset_name);
savename_2p = sprintf('%s-2P.hdf5', dataset_name);

save_movie_to_hdf5(M_1p_chopped, savename_1p);
save_movie_to_hdf5(M_2p_chopped, savename_2p);

save('preproc_1p2p', 'dataset_name', 'keep_frames', 'keep_cols_2p', 'keep_rows_2p');

% Move files to subdirectory
mkdir('1P');
movefile(savename_1p, '1P');
mkdir('2P');
movefile(savename_2p, '2P');

%% 1P cell extraction: EXTRACT

% Prior to cell extraction, run:
%   - Motion correction (TurboReg)
%   - Cropping (for motion correction edge artifacts)

filename_1p = get_most_recent_file('', '*.hdf5');
fprintf('Running EXTRACT on "%s"...\n', filename_1p);

config = get_defaults([]);
% config.preprocess = 0;
config.num_partitions_x = 1;
config.num_partitions_y = 1;
config.avg_cell_radius = 10;

output = extractor(sprintf('%s:/Data/Images', filename_1p), config);
import_extract(output);

% Retrieve the version of the movie that EXTRACT "sees"
M_orig = load_movie(filename_1p);
M = preprocess_movie(M_orig, config);
clear M_orig;

[~, name] = fileparts(filename_1p);
save_movie_to_hdf5(M, sprintf('%s_ext.hdf5', name));
