function RT_delay_by_frame = analyze_delay(saleae_file, si_integration_file)

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
fprintf('analyze_bmi_delay:\n  Found %d imaging frames with period %.1f ms\n',...
    num_frames, frame_period * 1000.0);

RT_clk_rise_times = find_edges(data, RT_clk_ch);
RT_clk_fall_times = find_edges(data, RT_clk_ch, 1);

RT_clk_times = [RT_clk_rise_times RT_clk_fall_times]';
RT_clk_times = RT_clk_times(:);

% Load ScanImage integration file
%------------------------------------------------------------
data_si = readmatrix(si_integration_file);
RT_processed_frames = data_si(:,2);
RT_dropped_frames = setdiff(1:num_frames, RT_processed_frames)';
num_dropped_frames = length(RT_dropped_frames);
fprintf('  Found %d dropped frames (%.1f%%)\n',...
    num_dropped_frames, num_dropped_frames/num_frames * 100.0);

if length(RT_processed_frames) == (length(RT_clk_times) - 1)
    cprintf('blue', '  Warning: Number of RT clock edges in Saleae exceeds that of ScanImage log by 1. Omitting last RT clock edge!\n');
    RT_clk_times = RT_clk_times(1:end-1);
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
    max_RT_delay * 1000.0, max_RT_delay/frame_period);

% Visualize results
%------------------------------------------------------------
t_lims = [1 num_frames];
stem(RT_delay_by_frame, '.', 'MarkerSize', 12);
% grid on;
hold on;
plot(t_lims, frame_period*[1 1], ':', 'LineWidth', 2, 'Color', [0.4660 0.6740 0.1880]); % Green
plot(t_lims, 2*frame_period*[1 1], ':', 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]); % Orange
plot(t_lims, 3*frame_period*[1 1], ':', 'LineWidth', 2, 'Color', [0.6350 0.0780 0.1840]); % Red
hold off;
xlabel('Frame index');
ylabel('BMI output delay (s)');
set(gca, 'TickLength', [0 0]);
xlim(t_lims);
zoom xon;