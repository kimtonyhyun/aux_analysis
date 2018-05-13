clear;

%% Load PrL data

dataset_name = dirname;
ds = DaySummary(data_sources, 'cm01-fix', 'noprobe');

%% Decoder params

pos = 0.1:0.1:0.9;

lambda1 = 0.1;
lambda2 = 0.0;

num_runs = 512;

%% END decode
decode_target = 'END'; %#ok<*NASGU>
selected_trials = ds.filter_trials('start', 'west'); % Select changing path

% - traces: Raw fluorescence trace
% - copy: Trace value if event, 0 if no event
% - copy_zeroed:
% - box: Event amplitude if event, 0 if no event (acausal)
% - binary: 1 if event, 0 if no event (acausal)
fill_type = 'traces';
alg1 = my_algs('linsvm', lambda1);
alg2 = my_algs('linsvm', lambda2);
[perf1, info1] = decode_end(alg1, ds, pos, selected_trials, fill_type, num_runs);
[perf2, info2] = decode_end(alg2, ds, pos, selected_trials, fill_type, num_runs);

%% Decoder visualization

plot(pos([1 end]), perf1.baseline_error*[1 1], 'k--');

hold on;
errorbar(pos, perf1.test_error(:,1), perf1.test_error(:,2)/sqrt(num_runs), 'b');
errorbar(pos, perf1.train_error(:,1), perf1.train_error(:,2)/sqrt(num_runs), 'b--');
errorbar(pos, perf2.test_error(:,1), perf2.test_error(:,2)/sqrt(num_runs), 'r');
errorbar(pos, perf2.train_error(:,1), perf2.train_error(:,2)/sqrt(num_runs), 'r--');
hold off;
xlim([0 1]);
ylim([0 0.5]);
grid on;
xlabel('Position in trial (normalized)');
ylabel('Decoder error (mean \pm s.e.m.)');
alg1_name = sprintf('\\lambda=%.2f', lambda1);
alg2_name = sprintf('\\lambda=%.2f', lambda2);
legend('Baseline',...
       sprintf('%s (test)', alg1_name), sprintf('%s (train)', alg1_name),...
       sprintf('%s (test)', alg2_name), sprintf('%s (train)', alg2_name),...
       'Location', 'NorthEast');
title(sprintf('%s: %s decoding', dataset_name, decode_target));