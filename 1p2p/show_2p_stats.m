clear all;

mouse_name = dirname;
datasets = dir(sprintf('%s-*', mouse_name));
datasets = datasets([datasets.isdir]);
num_datasets = length(datasets);

% Parse depths from the dataset name
depths = zeros(num_datasets, 1);
for k = 1:num_datasets
    [~, depth_str] = strtok(datasets(k).name, '_');
    depths(k) = str2double(depth_str(2:end));
end

%% Load the total number of 2P cells
% NOTE: This computation does not correct for the "Out of FOV" tally

num_2p_cells = zeros(num_datasets, 1);
for k = 1:num_datasets
    path_to_rec = fullfile(datasets(k).name, '2P/merge/ls');
    path_to_rec = get_most_recent_file(path_to_rec, 'rec_*.mat');
    rd = load(path_to_rec, 'info');
    num_2p_cells(k) = rd.info.num_pairs;
end

%% Load the number of 2P cells recaptured in 1P, and their SNRs

num_matched = zeros(num_datasets, 1);
snrs = cell(num_datasets, 1);
for k = 1:num_datasets
    path_to_matched_corrlist = fullfile(datasets(k).name, 'matched_corrlist.mat');
    mc = load(path_to_matched_corrlist);
    num_matched(k) = size(mc.matched_corrlist, 1);
    
    path_to_matched_snrs = fullfile(datasets(k).name, 'matched_snr.mat');
    ms = load(path_to_matched_snrs);
    snrs{k} = ms.snr_slopes;
end

%%

figure;
set(gcf, 'DefaultAxesFontSize', 14);

subplot(121);
plot(depths, num_matched./num_2p_cells, 'k.', 'MarkerSize', 18);
grid on;
ylim([0 1]);
set(gca, 'TickLength', [0 0]);
xlabel('Depth (um)');
ylabel({'Fraction of 2P cells found in 1P', '(No "Out of FOV" correction!)'});

subplot(122);
boxplot_wrapper(depths, snrs);
grid on;
xlabel({'Depth (um)', 'Note: x-axis is not to scale'});
ylabel({'Cell-by-cell 1P:2P SNR ratio', '(<1 means 2P better, >1 means 1P better)'});
ylim([0 3]);

% suptitle(mouse_name);

%% Show the full SNR histograms, in descending order

figure;
set(gcf, 'DefaultAxesFontSize', 14);

[~, sorted_inds] = sort(depths, 'ascend');

x = -1.5:0.05:1.5;
for k = 1:num_datasets
    subplot(num_datasets, 1, k);
    ind = sorted_inds(k);
    histogram(log10(snrs{ind}), x);
    ylabel({sprintf('Depth = %.0f um', depths(ind)),...
            sprintf('(%s)', datasets(ind).name)}, 'Interpreter', 'none', 'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
    set(gca, 'TickLength', [0 0]);
    grid on;
    if k == 1
        title(mouse_name);
    end
end
xlabel({'log_{10}(1P:2P SNR ratio)', 'Negative means 2P better; Positive means 1P better'});
% suptitle(mouse_name);