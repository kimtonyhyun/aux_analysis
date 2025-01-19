function [m, s] = validate_rt_processing(saleae_file, si_integration_file)
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
%
% Outputs are mainly organized into two structs:
%   - m: Quantities as expected from Matlab/ScanImage
%   - s: Quantities as measured from Saleae log
%
% Associated visualization functions:
%   - bmi.plot_RT_delays(s);

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

RT_clk_ch = 0;
frame_clk_ch = 1;

s.frame_clk.start_times = find_edges(data, frame_clk_ch);
s.frame_clk.end_times = find_edges(data, frame_clk_ch, 1); % Negedge

s.frame_clk.period = mean(diff(s.frame_clk.start_times));
s.num_frames = length(s.frame_clk.start_times);
fprintf('validate_rt_processing:\n  Saleae shows %d imaging frames with period %.1f ms\n',...
    s.num_frames, s.frame_clk.period * 1e3);

s.RT_clk_times = find_edges(data, RT_clk_ch, 'both'); % Detect both rising and falling edges
num_RT_clks = length(s.RT_clk_times);

% Load ScanImage integration file
%------------------------------------------------------------
data_si = readmatrix(si_integration_file);
m.RT_processed_frames = data_si(:,2);
m.RT_dropped_frames = setdiff(1:s.num_frames, m.RT_processed_frames)';

num_processed_frames = length(m.RT_processed_frames);
num_dropped_frames = length(m.RT_dropped_frames);

if num_dropped_frames == 0
    text_color = 'blue';
else
    text_color = 'red';
end
cprintf(text_color, '  Found %d dropped frames in SI integration log (%.1f%%)\n',...
    num_dropped_frames, num_dropped_frames/s.num_frames * 100.0);

if num_processed_frames == num_RT_clks
    cprintf('blue', '  Number of RT clock edges in Saleae matches that of IntegrationRois log\n');
elseif num_processed_frames == (num_RT_clks - 1)
    cprintf('red', '  Warning: Number of RT clock edges in Saleae exceeds that of IntegrationRois log by 1. Omitting last RT clock edge!\n');
    s.RT_clk_times = s.RT_clk_times(1:end-1);
else
    cprintf('red', 'Number of RT clock edges in Saleae does NOT match that of IntegrationRois log!\n');
end

% Compute the per-frame RT output time and delay
%------------------------------------------------------------
s.RT_output_time_by_frame = Inf * ones(s.num_frames, 1);
for k = 1:num_processed_frames
    frame_ind = m.RT_processed_frames(k);
    s.RT_output_time_by_frame(frame_ind) = s.RT_clk_times(k);
end

% If a frame's RT output was dropped by ScanImage, then RT_delay_by_frame
% for that frame is Inf
s.RT_delay_by_frame = s.RT_output_time_by_frame - s.frame_clk.end_times;

for k = 1:3
    num_frames_within_delay = sum(s.RT_delay_by_frame < k*s.frame_clk.period);
    fprintf('  Number of frames processed within %d frame period: %d (%.1f%%)\n',...
        k, num_frames_within_delay, num_frames_within_delay/s.num_frames * 100.0);
end

nonInf_RT_delay_by_frame = s.RT_delay_by_frame(~isinf(s.RT_delay_by_frame));

avg_RT_delay = mean(nonInf_RT_delay_by_frame);
fprintf('  Average delay: %.1f ms (=%.3f frames)\n',...
    avg_RT_delay * 1e3, avg_RT_delay/s.frame_clk.period);

max_RT_delay = max(nonInf_RT_delay_by_frame);
fprintf('  Maximum delay: %.1f ms (=%.3f frames)\n',...
    max_RT_delay * 1e3, max_RT_delay/s.frame_clk.period);
