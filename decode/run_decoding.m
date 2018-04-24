clear;

%%
sources = data_sources;

ds_prl = DaySummary(sources, 'prl_cm01_fix');
ds_hpc = DaySummary(sources, 'hpc_cm01_fix');

%%
trials = ds_prl.filter_trials('start', 'west');
target = {ds_prl.trials.end};
fill_type = 'traces';

pos = 0.1:0.1:0.9;

l1_reg = 0.1;
alg = my_algs('linsvm', l1_reg);
num_runs = 512;

%%
fprintf('Decoding PrL neurons (N=%d)...\n', ds_prl.num_classified_cells);
[prl_test_error, prl_train_error] = decode_end(alg, ds_prl, pos, trials, target, fill_type, num_runs);

%%
fprintf('Decoding HPC neurons (N=%d) ...\n', ds_hpc.num_classified_cells);
[hpc_test_error, hpc_train_error] = decode_end(alg, ds_hpc, pos, trials, target, fill_type, num_runs);

%% Baseline performance by guessing one outcome
trial_targets = target(trials);
north_end_trials = strcmp(trial_targets, 'north');
north_frac = sum(north_end_trials)/sum(trials);

baseline_perf = min(north_frac, 1-north_frac);

%%

plot(pos([1 end]), baseline_perf*[1 1], 'k--');
hold on;
errorbar(pos, prl_test_error(:,1), prl_test_error(:,2)/sqrt(num_runs), 'b');
errorbar(pos, prl_train_error(:,1), prl_train_error(:,2)/sqrt(num_runs), 'b--');
errorbar(pos, hpc_test_error(:,1), hpc_test_error(:,2)/sqrt(num_runs), 'r');
errorbar(pos, hpc_train_error(:,1), hpc_train_error(:,2)/sqrt(num_runs), 'r--');
hold off;
xlim([0 1]);
ylim([0 0.5]);
grid on;
xlabel('Position in trial (normalized');
ylabel('Decoder error (mean \pm s.e.m.)');
legend('Baseline', 'PRL (test)', 'PRL (train)',...
       'HPC (test)', 'HPC (train)',...
       'Location', 'NorthEast');
title(sprintf('c14m6d10 End arm decoding (fill=%s, alg=%s)',...
    strrep(fill_type,'_','\_'), alg.name));

%% Evaluate a specific position in detail
position_to_eval = 1.0;

[X, ks, ~, sampled_frames] = ds_dataset(ds_prl,...
    'selection', position_to_eval,...
    'filling', fill_type,...
    'trials', trials,...
    'target', target);

sampled_frames = sampled_frames(trials);

%%
trial_inds = find(trials);

figure;
imagesc(ds_prl.get_behavior_trial_frame(trial_inds(1), sampled_frames(1)));
axis image;
colormap gray;
hold on;

for k = 1:length(trial_inds)
    trial_ind = trial_inds(k);
    sampled_frame = sampled_frames(k);
    centroid = ds_prl.trials(trial_ind).centroids(sampled_frame,:);
    if strcmp(ds_prl.trials(trial_ind).end, 'north')
        color = 'r';
    else
        color = 'y';
    end
    plot(centroid(1), centroid(2), '.', 'Color', color);
end
title(sprintf('c14m6d10 Actual positions for x=%.2f', position_to_eval));