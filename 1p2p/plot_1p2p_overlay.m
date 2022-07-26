clear all;

dataset_name = dirname;

path_to_1P = '1P';
path_to_2P = '2P';

ds = DaySummary([], fullfile(path_to_1P, 'merge/ls'));
ds2 = DaySummary([], fullfile(path_to_2P, 'merge/ls'));

match = load('match_pre.mat'); % Contains affine transformation info

M = load_movie_from_hdf5(get_most_recent_file(path_to_1P, '*_cr.hdf5'), [1 1000]);
A = mean(M,3);

M2 = load_movie_from_hdf5(get_most_recent_file(path_to_2P, '*_nc.hdf5'), [1 1000]);
A2 = mean(M2,3);

%%

imagesc(A, [0 15000]);
axis image; colormap gray;
set(gca, 'XTick', []);
set(gca, 'YTick', []);

hold on; plot_boundaries(ds, 'color', 'b', 'linewidth', 2);
hold on; plot_boundaries(ds2, 'color', 'r', 'tform', match.info.tform);

title(sprintf('%s\n%d cells (1P; blue) vs. %d cells (2P; red)',...
    dataset_name, ds.num_classified_cells, ds2.num_classified_cells));
set(gca, 'FontSize', 18);

%%

print('-dpng', 'overlay_post_im');