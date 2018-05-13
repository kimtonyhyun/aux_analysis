clear;

%% Load data

dataset_name = dirname;
sources = data_sources;

ds = DaySummary(sources, 'cm01-fix', 'noprobe');

%% Decoder params

wn_trials = ds.filter_trials('start', 'west', 'end', 'north');
ws_trials = ds.filter_trials('start', 'west', 'end', 'south');
trials = wn_trials | ws_trials;

pos = 0.15;

alg = my_algs('linsvm', 0.1); % L1 reg
num_runs = 512;

%% Confirm position sampling
pos_frames = compute_pos_frames(ds, pos);
plot_centroids(ds, {wn_trials, ws_trials}, pos_frames);
title(sprintf('%s: Sampled positions for pos=%.2f', dataset_name, pos));

%% END decode

[traces_perf, decode_info] = decode_end(alg, ds, pos, trials, 'traces', num_runs);
% copy_perf = decode_end(alg, ds, pos, trials, 'copy', num_runs);
% copyzeroed_perf = decode_end(alg, ds, pos, trials, 'copy_zeroed', num_runs);
% box_perf = decode_end(alg, ds, pos, trials, 'box', num_runs);

%% Look at example decoder weights
bs = zeros(ds.num_cells, num_runs);
num_zero_weights = zeros(1, num_runs);
num_nonzero_weights = zeros(1, num_runs);
eps = 1e-4;

for k = 1:num_runs
    b = decode_info.models{k}.Beta;
    bs(:,k) = b;
    
    max_b = max(abs(b));
    num_zero_weights(k) = sum(abs(b)<eps*max_b);
    num_nonzero_weights(k) = ds.num_cells - num_zero_weights(k);
end

%%
for k = 1:1
    stem(bs(:,k),'k.');
    hold on;
end
hold off;

% plot(mean(bs),'r.-');

%% Look at some single cell rasters
cell_idx = 263;
examine_fills(ds, cell_idx, wn_trials, ws_trials, pos_frames);
suptitle(sprintf('%s: Cell %d, aligned to pos=%.2f', dataset_name, cell_idx, pos));
