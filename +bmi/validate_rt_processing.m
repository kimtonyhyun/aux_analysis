function RT_delay_by_frame = validate_rt_processing(saleae_file, si_integration_file)
% Validate real-time processing results, i.e.:
% - Check whether there are any dropped frames in the SI integration file
% - Confirm that the number of RT clock edges matches the number of
%     processed frames in the SI integration file
%
% TODO:
% 1. Confirm that the classifier output at the time of RT clock edge 
%    matches the intended one as logged in the SI integration file
% 2. Calculate the expected "BMI counts" for each Matlab read, so that we
%    can verify against the downstream Matlab log.

if ~exist('saleae_file', 'var')
    saleae_file = 'untitled.csv';
end

if ~exist('si_integration_file', 'var')
    si_integration_file = get_most_recent_file('.', '*_IntegrationRois_*.csv');
    fprintf('Using "%s"...\n', si_integration_file);
end

% Load Saleae data
%------------------------------------------------------------
data = load(saleae_file);

frame_clk_ch = 1; % New format
RT_clk_ch = 0;

% frame_clk_ch = 0; % Old format
% RT_clk_ch = 7;

frame_start_times = find_edges(data, frame_clk_ch);
frame_end_times = find_edges(data, frame_clk_ch, 1); % Negedge

frame_period = mean(diff(frame_start_times));
num_frames = length(frame_start_times);
fprintf('analyze_bmi_delay:\n  Found %d imaging frames in Saleae log with period %.1f ms\n',...
    num_frames, frame_period * 1e3);

RT_clk_times = find_edges(data, RT_clk_ch, 'both'); % Detect both rising and falling edges

% Load ScanImage integration file
%------------------------------------------------------------
data_si = readmatrix(si_integration_file);
RT_processed_frames = data_si(:,2);
RT_dropped_frames = setdiff(1:num_frames, RT_processed_frames)';
num_dropped_frames = length(RT_dropped_frames);
if num_dropped_frames == 0
    text_color = 'blue';
else
    text_color = 'red';
end
cprintf(text_color, '  Found %d dropped frames in SI integration log (%.1f%%)\n',...
    num_dropped_frames, num_dropped_frames/num_frames * 100.0);

if length(RT_processed_frames) == length(RT_clk_times)
    cprintf('blue', '  Number of RT clock edges in Saleae matches that of ScanImage log\n');
elseif length(RT_processed_frames) == (length(RT_clk_times) - 1)
    cprintf('red', '  Warning: Number of RT clock edges in Saleae exceeds that of ScanImage log by 1. Omitting last RT clock edge!\n');
    RT_clk_times = RT_clk_times(1:end-1);
else
    cprintf('red', 'Number of RT clock edges in Saleae does NOT match that of ScanImage log!\n');
end

% Compute the per-frame RT output time and delay
RT_output_time_by_frame = Inf * ones(num_frames, 1);
for k = 1:length(RT_processed_frames)
    frame_ind = RT_processed_frames(k);
    RT_output_time_by_frame(frame_ind) = RT_clk_times(k);
end

RT_delay_by_frame = RT_output_time_by_frame - frame_end_times;

for k = 1:3
    num_frames_within_delay = sum(RT_delay_by_frame < k*frame_period);
    fprintf('  Number of frames processed within %d frame period: %d (%.1f%%)\n',...
        k, num_frames_within_delay, num_frames_within_delay/num_frames * 100.0);
end
max_RT_delay = max(RT_delay_by_frame(~isinf(RT_delay_by_frame)));
fprintf('  Maximum delay: %.1f ms (=%.3f frames)\n',...
    max_RT_delay * 1e3, max_RT_delay/frame_period);

% Visualize results
%------------------------------------------------------------
t_lims = [1 num_frames];
stem(RT_delay_by_frame * 1e3, '.', 'MarkerSize', 12);
% grid on;
hold on;
plot(t_lims, frame_period*[1 1] * 1e3, ':', 'LineWidth', 2, 'Color', [0.4660 0.6740 0.1880]); % Green
plot(t_lims, 2*frame_period*[1 1] * 1e3, ':', 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]); % Orange
plot(t_lims, 3*frame_period*[1 1] * 1e3, ':', 'LineWidth', 2, 'Color', [0.6350 0.0780 0.1840]); % Red
hold off;
xlabel('Frame index');
ylabel('BMI output delay (ms)');
set(gca, 'TickLength', [0 0]);
xlim(t_lims);
zoom xon;