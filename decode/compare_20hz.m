clear;

%% Load PrL data

dataset_name = dirname;
ds_10hz = DaySummary(data_sources, 'cm01-fix');
ds_20hz = DaySummary(data_sources_20hz, 'cm01-fix_20hz');

%% Decoder params

pos = 0.1:0.1:0.9;

% - traces: Raw fluorescence trace
% - copy: Trace value if event, 0 if no event
% - copy_zeroed:
% - box: Event amplitude if event, 0 if no event (acausal)
% - binary: 1 if event, 0 if no event (acausal)
fill_type = 'traces';

alg = my_algs('linsvm', 0.1); % L1 reg
num_runs = 512;

%% START decode
decode_target = 'START'; %#ok<*NASGU>
selected_trials = ds_20hz.filter_trials('end', 'north');

fprintf('Decoding at 20 Hz...\n');
[test_error_20hz, train_error_20hz, info] = decode_start(alg, ds_20hz, pos, selected_trials, fill_type, num_runs); %#ok<*ASGLU>

fprintf('Decoding at 10 Hz...\n');
[test_error_10hz, train_error_10hz] = decode_start(alg, ds_10hz, pos, selected_trials, fill_type, num_runs);

%% END decode
decode_target = 'END'; %#ok<*NASGU>
selected_trials = ds_20hz.filter_trials('start', 'west'); % Select changing path

fprintf('Decoding at 20 Hz...\n');
[test_error_20hz, train_error_20hz, info] = decode_end(alg, ds_20hz, pos, selected_trials, fill_type, num_runs); %#ok<*ASGLU>

fprintf('Decoding at 10 Hz...\n');
[test_error_10hz, train_error_10hz] = decode_end(alg, ds_10hz, pos, selected_trials, fill_type, num_runs);

%% ERROR decode
decode_target = 'ERROR';
trials = ds_20hz.filter_trials();

fprintf('Decoding at 20 Hz...\n');
[test_error_20hz, train_error_20hz, info] = decode_error(alg, ds_20hz, pos, selected_trials, fill_type, num_runs);

fprintf('Decoding at 10 Hz...\n');
[test_error_10hz, train_error_10hz] = decode_error(alg, ds_10hz, pos, selected_trials, fill_type, num_runs);

%% Decoder visualization

plot(pos([1 end]), info.baseline_error*[1 1], 'k--');

hold on;
errorbar(pos, test_error_20hz(:,1), test_error_20hz(:,2)/sqrt(num_runs), 'b');
errorbar(pos, train_error_20hz(:,1), train_error_20hz(:,2)/sqrt(num_runs), 'b--');
errorbar(pos, test_error_10hz(:,1), test_error_10hz(:,2)/sqrt(num_runs), 'r');
errorbar(pos, train_error_10hz(:,1), train_error_10hz(:,2)/sqrt(num_runs), 'r--');
hold off;
xlim([0 1]);
ylim([0 0.5]);
grid on;
xlabel('Position in trial (normalized)');
ylabel('Decoder error (mean \pm s.e.m.)');
legend('Baseline', '20 Hz (test)', '20 Hz (train)',...
       '10 Hz (test)', '10 Hz (train)',...
       'Location', 'NorthEast');
title(sprintf('%s: %s decoding (fill=%s, alg=%s)',...
    dataset_name, decode_target, strrep(fill_type,'_','\_'), alg.name));