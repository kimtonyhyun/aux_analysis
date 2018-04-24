clear;

%%
sources = data_sources;

ds_prl = DaySummary(sources, 'prl_cm01_fix');
ds_hpc = DaySummary(sources, 'hpc_cm01_fix');

%%
trials = ds_prl.filter_trials('start', 'west');
trial_inds = find(trials);
target = {ds_prl.trials.end};
fill_type = 'traces';

pos = 0.1:0.1:0.9;

l1_reg = 0.1;
alg = my_algs('linsvm', l1_reg);
num_runs = 512;

%%
fprintf('Decoding PrL neurons (N=%d)...\n', ds_prl.num_classified_cells);
[prl_test_error, prl_train_error] = decode_end(alg, ds_prl, pos, trials, fill_type, num_runs);

%%
fprintf('Decoding HPC neurons (N=%d) ...\n', ds_hpc.num_classified_cells);
[hpc_test_error, hpc_train_error] = decode_end(alg, ds_hpc, pos, trials, fill_type, num_runs);

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
ds = ds_prl;
position_to_eval = 0.3;

[X, ks, ~, sampled_frames] = ds_dataset(ds,...
    'selection', position_to_eval,...
    'filling', fill_type,...
    'trials', trials,...
    'target', target);

sampled_frames = sampled_frames(trials);

%% Display mouse position

figure;
imagesc(ds.get_behavior_trial_frame(trial_inds(1), sampled_frames(1)));
axis image;
colormap gray;
hold on;

for k = 1:length(trial_inds)
    trial_ind = trial_inds(k);
    sampled_frame = sampled_frames(k);
    centroid = ds.trials(trial_ind).centroids(sampled_frame,:);
    if strcmp(ds.trials(trial_ind).end, 'north')
        color = 'r';
    else
        color = 'y';
    end
    plot(centroid(1), centroid(2), '.', 'Color', color);
end
title(sprintf('c14m6d10 Actual positions for x=%.2f', position_to_eval));

%% Show traces aligned to position
num_cells = ds.num_classified_cells;
c = 1:num_cells;

X2 = zeros(75, num_cells);

for k = 1:75
    trial_idx = trial_inds(k);
    trial_target = trial_targets{k};
    sampled_frame = sampled_frames(k);

    traces = ds.get_trial(trial_idx,'norm');
    traces_pos = traces(:,sampled_frame);
    num_frames = size(traces,2);
    t = (1:num_frames)-sampled_frame;
    
    X2(k,:) = traces_pos';
    
    % % Sort cells by amplitude
    % [traces_pos, sort_inds] = sort(traces_pos, 'descend');
    % traces = traces(sort_inds,:);

    subplot(1,3,[1 2]);
    surf(t,c,traces);
    hold on;
    plot3(zeros(1,num_cells), c, traces_pos, 'k');
    hold off;
    shading interp;
    xlabel(sprintf('Frame (aligned to pos=%.2f)', position_to_eval));
    ylabel('Cell');
    zlabel('Fluorescence (norm)');
    title(sprintf('Trial %d - %s end', trial_idx, trial_target));
    xlim([-100 100]);
    ylim([1 num_cells]);
    set(gca,'YDir','Reverse');
    view([-8 86]);

    subplot(1,3,3);
    if strcmp(trial_target, 'north')
        color = 'r';
    else
        color = 'b';
    end
    plot(traces_pos,c,'.-','Color',color);
    xlim([0 1]);
    ylim([1 num_cells]);
    set(gca,'YDir','Reverse');
    grid on;
    xlabel('Fluorescence');
    ylabel('Cell');
    title(sprintf('F@pos=%.2f', position_to_eval));
    
    drawnow;
%     print('-dpng',sprintf('c14m6d10-trial%03d.png', trial_idx));
end