%% Evaluate post-merge 1P/2P filters

clear all;

path_to_dataset1 = '1P';
path_to_dataset2 = '2P';

ds = DaySummary([], fullfile(path_to_dataset1, 'merge/ls'));
ds2 = DaySummary([], fullfile(path_to_dataset2, 'merge/ls'));

%% Match 1P/2P

close all;

load('match_pre.mat', 'info');
fps = 25.4;

[matched, non_matched] = match_1p2p(ds, ds2, info.tform, fps);

save('corrlist', 'matched', 'non_matched');
cprintf('blue', 'Found %d matched cells between 1P and 2P\n', size(matched,1));

%% Show the spatial alignment, using previously computed transformation

load('match_pre.mat', 'info');
m = load('corrlist.mat');

figure;
plot_boundaries(ds, 'color', 'b', 'linewidth', 2, 'fill', m.matched(:,1));
hold on;
plot_boundaries(ds2, 'color', 'r', 'linewidth', 1, 'fill', m.matched(:,2), 'tform', info.tform);
hold off;

dataset_name = dirname;
num_cells_1p = ds.num_classified_cells;
num_cells_2p = ds2.num_classified_cells;
num_match = size(m.matched,1);

title_str = sprintf('%s (POST-merge)\n%s (%d cells; blue) vs. %s (%d cells; red)\nFilled indicates match (%d cells)',...
    dataset_name, path_to_dataset1, num_cells_1p, path_to_dataset2, num_cells_2p, num_match);
title(title_str);
set(gca, 'FontSize', 18);

%% Save image of the spatial alignment

print('-dpng', 'overlay_post');

%% Compute all 1P:2P transfer function slopes. Note:
%   - slope > 1 means that 1P had higher SNR
%   - slope < 1 means that 2P had higher SNR

corrlist = load('corrlist.mat');
num_matches = size(corrlist.matched, 1);
snr_slopes = zeros(num_matches, 1);
for k = 1:num_matches
    match = corrlist.matched(k,:);
    tr1 = ds.get_trace(match(1), 'zsc')';
    tr2 = ds2.get_trace(match(2), 'zsc')';
    fit = fit_1p2p(tr1, tr2, 25.4);
    snr_slopes(k) = fit.slope;
end

log_snrs = log10(snr_slopes);
% save('matched_snr', 'snr_slopes');

%% Display SNR distribution

load('matched_snr');
log10_snr_slopes = log10(snr_slopes);

x = -1.2:0.05:1.2;
histogram(log10_snr_slopes, x);
xlabel({'log_{10}(1P:2P SNR ratio)', 'Negative means 2P better; Positive means 1P better'});
ylabel('Distribution (num cells)');
title(dirname);
grid on;