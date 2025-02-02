function [m, s, s_aux] = validate_screen(matlab_results_file)
% Validate screen function during the behavioral task, i.e.:
%   - Confirm there are expected number of screen transitions as measured 
%     by the photodiode
%   - Calculate precise latency of screen updates using photodiode data
%
% Assumes that the Saleae data has been exported as:
%   - digital.csv: All digital traces (i.e. no analog)
%   - analog.csv: Photodiode trace only
%
% Outputs are mainly organized into two structs:
%   - m: Quantities as expected from Matlab
%   - s: Quantities as measured from Saleae log
%
% Example:
%   [m, s] = bmi.validate_screen('Results_phase9_AB_flash_250113-122604.mat');
%   all_screen_latency = cell2mat(s.screen_update_latency) * 1e3; % ms

if ~exist('matlab_results_file', 'var')
    matlab_results_file = get_most_recent_file('.', 'Results_*.mat');
    fprintf('Using "%s"...\n', matlab_results_file);
end

% Parse data from Matlab side
%------------------------------------------------------------
rdata = load(matlab_results_file);
results = rdata.results;

% Find actual number of trials (i.e. with nonempty trial result)
m.num_trials = length([results.x0]);

% Format: [num_all_reads, num_reads_with_movement]
m.num_reads = zeros(m.num_trials, 2);

nonzero_read_inds = cell(m.num_trials, 1);

for k = 1:m.num_trials
    counts_k = results(k).counts;
    
    nonzero_read_inds{k} = (counts_k~=0);
    m.num_reads(k,:) = [length(counts_k) sum(counts_k~=0)];
end

% Parse data from Saleae side
%------------------------------------------------------------
sdata = readmatrix('digital.csv');

trial_ch = 5;
matlab_read_ch = 6;
screen_ind_ch = 7;

s_aux.trial_times = find_pulses(sdata, trial_ch);
s.num_trials = size(s_aux.trial_times, 1);

if m.num_trials == s.num_trials
    cprintf('blue', 'Matlab and Saleae agree on the number of trials\n');
else
    cprintf('red', 'Matlab and Saleae report DIFFERENT numbers of trials!\n');
end

% Note: We measure Matlab read times by its FALLING edge
read_times = find_edges(sdata, matlab_read_ch, 'neg');
s.read_times = parse_times_by_trial(read_times, s_aux.trial_times);
s.read_times_with_movement = cell(s.num_trials, 1);
for k = 1:s.num_trials
    s.read_times_with_movement{k} = s.read_times{k}(nonzero_read_inds{k});
end

% We use the digitized photodiode signal to determine the _number_ of
% screen transitions, but won't use it for the precise timings
approx_screen_update_times = find_edges(sdata, screen_ind_ch, 'both');
s_aux.approx_screen_update_times = parse_times_by_trial(approx_screen_update_times, s_aux.trial_times);

% Omit the first screen indicator update time, which is just the first
% frame of a trial and does not correspond to movement
s_aux.approx_screen_update_times = cellfun(@(x) x(2:end), s_aux.approx_screen_update_times,...
    'UniformOutput', false);

% Format: [num_all_reads, num_display_updates]
s.num_reads = cat(2,...
    cellfun(@length, s.read_times, 'UniformOutput', true), ...
    cellfun(@length, s_aux.approx_screen_update_times, 'UniformOutput', true));

if all(m.num_reads == s.num_reads)
    cprintf('blue', 'Matlab and Saleae agree on the number of Matlab reads and screen transitions\n');
else
    cprintf('red', 'Detected mismatch in Matlab reads and/or screen transitions\n');
end

% Finally, we compute the exact screen transition times by analyzing the
% analog photodiode signal. This computation has two numerical parameters
% that may need to be tuned to get the correct result. Periodically check
% the result against the native Saleae recording!
%------------------------------------------------------------
threshold_percentile = 99;
median_filter_window = 3;

adata = readmatrix('analog.csv');

t = adata(:,1);
dt = mean(diff(t));
f = adata(:,2);

dfdt = abs(gradient(f)/dt); % Units: Volts/s

threshold = prctile(dfdt, threshold_percentile);
bin_f = single(dfdt > threshold);
bin_f = medfilt1(bin_f, median_filter_window);

screen_update_times = find_edges([t bin_f], 0);
s.screen_update_times = parse_times_by_trial(screen_update_times, s_aux.trial_times);

% Omit the first screen indicator update time, which is just the first
% frame of a trial and does not correspond to movement
s.screen_update_times = cellfun(@(x) x(2:end), s.screen_update_times,...
    'UniformOutput', false);

num_mismatch = 0;
for k = 1:s.num_trials
    sut_k = s.screen_update_times{k};
    num_updates_k = length(sut_k);

    asut_k = s_aux.approx_screen_update_times{k};
    num_approx_updates_k = length(asut_k);

    if num_updates_k ~= num_approx_updates_k
        cprintf('red', 'Trial %d: Found incorrect number of screen update times (got %d, expected %d)\n',...
            k, num_updates_k, num_approx_updates_k);
        num_mismatch = num_mismatch + 1;
    end
end

if num_mismatch == 0
    cprintf('blue', 'Calculated the correct number of screen update times from the analog photodiode trace\n')
end

% Calculate the latency from Matlab read to screen update
%------------------------------------------------------------
s.screen_update_latency = cellfun(@(x,y) x-y,...
    s.screen_update_times, s.read_times_with_movement, 'UniformOutput', false);