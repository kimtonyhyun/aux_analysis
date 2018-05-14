clear;

%% Load data

dataset_name = dirname;
sources = data_sources;

ds = DaySummary(sources, 'cm01-fix', 'noprobe');

%% Decoder params

wn_trials = ds.filter_trials('start', 'west', 'end', 'north');
ws_trials = ds.filter_trials('start', 'west', 'end', 'south');
trials = wn_trials | ws_trials;

pos = 0.2;
pos_frames = compute_pos_frames(ds, pos);

alg = my_algs('linsvm', 0.1); % L1 reg
num_runs = 512;

%% Confirm position sampling
plot_centroids(ds, {wn_trials, ws_trials}, pos_frames);
title(sprintf('%s: Sampled positions for pos=%.2f', dataset_name, pos));

%% END decode
[traces_perf, decode_info] = decode_end(alg, ds, pos, trials, 'traces', num_runs);

%% Combine model parameters
betas = zeros(ds.num_cells, num_runs);
for k = 1:num_runs
    betas(:,k) = decode_info.models{k}.Beta;
end

C = betas'*betas;
imagesc(C, [0 1]);

%% Look at some single cell rasters
cell_idx = 97;
examine_fills(ds, cell_idx, wn_trials, ws_trials, pos_frames);
suptitle(sprintf('%s: Cell %d, aligned to pos=%.2f', dataset_name, cell_idx, pos));
