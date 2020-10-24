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

%% Compute all 1P:2P transfer function slopes. Note:
%   - slope > 1 means that 1P had higher SNR
%   - slope < 1 means that 2P had higher SNR

load('matched_corrlist.mat');
num_matches = size(matched_corrlist, 1);
snr_slopes = zeros(num_matches, 1);
for k = 1:num_matches
    match = matched_corrlist(k,:);
    tr1 = ds.get_trace(match(1), 'zsc');
    tr2 = ds2.get_trace(match(2), 'zsc');
    snr_slopes(k) = fit_1p2p_slope(tr2, tr1);
end

save('matched_snr', 'snr_slopes');