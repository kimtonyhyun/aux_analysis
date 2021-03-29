%% Evaluate post-merge 1P/2P filters

clear all;

path_to_dataset1 = '1P';
path_to_dataset2 = '2P/sl1_d350';

ds = DaySummary([], fullfile(path_to_dataset1, 'merge/ls_ti6'));
% ds2 = DaySummary([], fullfile(path_to_dataset2, 'merge/ls'));
ds2 = DaySummary([], fullfile(path_to_dataset2, 'ext1/ls'));

%% Show the spatial alignment, using previously computed transformation

load('match_pre.mat', 'info');

% Note that we can continue to use the same 'selected_cells' IDs, because
% the transferred filters are _appended_ to the end of the original
% extraction output.
figure;
plot_boundaries(ds, 'color', 'b', 'linewidth', 2, 'fill', info.alignment.selected_cells(:,1));
hold on;
plot_boundaries(ds2, 'color', 'r', 'linewidth', 1, 'fill', info.alignment.selected_cells(:,2), 'tform', info.tform);
hold off;

dataset_name = dirname;
num_cells_1p = ds.num_classified_cells;
num_cells_2p = ds2.num_classified_cells;

title_str = sprintf('%s (POST-merge)\n%s (%d cells; blue) vs. %s (%d cells; red)',...
    dataset_name, path_to_dataset1, num_cells_1p, path_to_dataset2, num_cells_2p);
title(title_str);
set(gca, 'FontSize', 18);

%% Save image of the spatial alignment

print('-dpng', 'overlay_post');

%% Match 1P/2P

load('match_pre.mat', 'info');

close all;

matched_corrlist = match_1p2p(ds, ds2, info.tform);

save('matched_corrlist', 'matched_corrlist');
cprintf('blue', 'Found %d matched cells between 1P and 2P\n', size(matched_corrlist,1));
