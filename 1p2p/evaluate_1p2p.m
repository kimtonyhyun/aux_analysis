%% Evaluate post-merge 1P/2P filters

clear all;

ds = DaySummary([], '1P/merge/ls');
ds2 = DaySummary([], '2P/merge/ls');

%% Perform spatial alignment

[m_1to2, m_2to1, info] = run_alignment(ds, ds2);
save('match_post', 'm_1to2', 'm_2to1', 'info');

%% Save image of the initial spatial alignment

dataset_name = dirname;
num_cells_1p = ds.num_classified_cells;
num_cells_2p = ds2.num_classified_cells;

title_str = sprintf('%s (POST-merge)\n1P (%d cells; blue) vs. 2P (%d cells; red)',...
    dataset_name, num_cells_1p, num_cells_2p);
title(title_str);
set(gca, 'FontSize', 18);
print('-dpng', 'overlay_post');

%% Match 1P/2P

load('match_post.mat', 'info');
matched_corrlist = match_1p2p(ds, ds2, info.tform);

save('matched_corrlist', 'matched_corrlist');

%% Temporal correlations of matched corrlist

browse_corrlist(matched_corrlist, ds, ds2, 'names', {'1P', '2P'}, 'zsc');