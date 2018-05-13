clear;

%% Load PrL data

dataset_name = dirname;
ds = DaySummary(data_sources, 'cm01-fix', 'noprobe');

%% Decoder params

pos = 0.1:0.1:0.9;

alg = my_algs('linsvm', 0.1); % L1 reg
num_runs = 512;

%% END decode
decode_target = 'END'; %#ok<*NASGU>
selected_trials = ds.filter_trials('start', 'west'); % Select changing path

% - traces: Raw fluorescence trace
% - copy: Trace value if event, 0 if no event
% - copy_zeroed:
% - box: Event amplitude if event, 0 if no event (acausal)
% - binary: 1 if event, 0 if no event (acausal)
[perf_tr, info_tr] = decode_end(alg, ds, pos, selected_trials, 'traces', num_runs);
[perf_c, info_c] = decode_end(alg, ds, pos, selected_trials, 'copy', num_runs);

%% Decoder visualization

plot(pos([1 end]), perf_tr.baseline_error*[1 1], 'k--');

hold on;
errorbar(pos, perf_tr.test_error(:,1), perf_tr.test_error(:,2)/sqrt(num_runs), 'b');
errorbar(pos, perf_tr.train_error(:,1), perf_tr.train_error(:,2)/sqrt(num_runs), 'b--');
errorbar(pos, perf_c.test_error(:,1), perf_c.test_error(:,2)/sqrt(num_runs), 'r');
errorbar(pos, perf_c.train_error(:,1), perf_c.train_error(:,2)/sqrt(num_runs), 'r--');
hold off;
xlim([0 1]);
ylim([0 0.5]);
grid on;
xlabel('Position in trial (normalized)');
ylabel('Decoder error (mean \pm s.e.m.)');
legend('Baseline', 'traces (test)', 'traces (train)',...
       'copy (test)', 'copy (train)',...
       'Location', 'NorthEast');
title(sprintf('%s: %s decoding (alg=%s)',...
    dataset_name, decode_target, alg.name));