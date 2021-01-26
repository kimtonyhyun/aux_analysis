%% Evaluate post-merge 1P/2P filters

clear all;

path_to_dataset1 = '1P';
path_to_dataset2 = '2P';

ds = DaySummary([], fullfile(path_to_dataset1, 'merge/ls'));
ds2 = DaySummary([], fullfile(path_to_dataset2, 'merge/ls'));

%% Show the spatial alignment, using previously computed transformation

load('match_pre.mat', 'info');

% Note that we can continue to use the same 'selected_cells' IDs, because
% the transferred filters are _appended_ to the end of the original
% extraction output.
figure;
plot_boundaries_with_transform(ds, 'b', 2, info.alignment.selected_cells(:,1));
hold on;
plot_boundaries_with_transform(ds2, 'r', 1, info.alignment.selected_cells(:,2), info.tform);
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

close all;

matched_corrlist = match_1p2p(ds, ds2, info.tform);

save('matched_corrlist', 'matched_corrlist');
cprintf('blue', 'Found %d matched cells between 1P and 2P\n', size(matched_corrlist,1));

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

%% Display SNR distribution

load('matched_snr');
log10_snr_slopes = log10(snr_slopes);

x = -1.2:0.05:1.2;
histogram(log10_snr_slopes, x);
xlabel({'log_{10}(1P:2P SNR ratio)', 'Negative means 2P better; Positive means 1P better'});
ylabel('Distribution (num cells)');
title(dirname);
grid on;