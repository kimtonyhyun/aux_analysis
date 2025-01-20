function [m, s] = validate_rt_processing(saleae_file, si_integration_file)
% Validate real-time processing results, i.e.:
% - Check whether there are any dropped frames in the SI integration file
% - Confirm that the number of RT clock edges matches the number of
%     processed frames in the SI integration file
% - Confirm that RT preds (LL/L/0/R/RR) at each RT clock edge correctly
%     reproduces the RT prediction in the SI integration file
%
% Outputs are mainly organized into two structs:
%   - m: Quantities as expected from Matlab/ScanImage
%   - s: Quantities as measured from Saleae log
%
% Associated visualization functions:
%   - bmi.plot_RT_latency(s);
%

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
RT_pred_chs = [2 3 4 5 6]; % [LL, L, 0, R, RR]
matlab_read_ch = 7;

s.frame_times = find_edges(data, frame_clk_ch, 1); % Negedge
s.frame_period = mean(diff(s.frame_times));
s.num_frames = length(s.frame_times);
fprintf('validate_rt_processing:\n  Saleae shows %d imaging frames with period %.1f ms\n',...
    s.num_frames, s.frame_period * 1e3);

[s.RT_clk_times, edge_inds] = find_edges(data, RT_clk_ch, 'both'); % Detect both rising and falling edges
num_RT_clks = length(s.RT_clk_times);

s.RT_preds = data(edge_inds, 2 + RT_pred_chs);

s.matlab_read_times = find_edges(data, matlab_read_ch, 1); % Negedge
num_matlab_reads = length(s.matlab_read_times);

s.matlab_read_vals = zeros(num_matlab_reads, 1);
s.num_matlab_reads = num_matlab_reads; % Ordered this way for pretty struct formatting

% Load ScanImage integration file
%------------------------------------------------------------
data_si = readmatrix(si_integration_file); % [timestamp, frameNumber, ROI 1, ROI 2,...]
m.RT_processed_frames = data_si(:,2);
m.RT_dropped_frames = setdiff(1:s.num_frames, m.RT_processed_frames)';

% The last 7 "ROIs" are placeholders corresponding to RT calculations:
%   [LL, L, 0, R, RR, RT_clk, DecoderResult (analog)]
m.RT_preds = data_si(:,end-6:end);
m.RT_preds = m.RT_preds(:,1:5);

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
    % In previous (slow) PCs with dropped frames, we found that we get an
    % extra, falling RT clock edge at the end of the recording. This extra
    % edge doesn't correspond to a processed frame, but seems to be just
    % the ScanImage outputs turning off at the end of a recording.
    cprintf('red', '  Warning: Number of RT clock edges in Saleae exceeds that of IntegrationRois log by 1. Omitting last RT clock edge!\n');
    s.RT_clk_times = s.RT_clk_times(1:end-1);
else
    cprintf('red', 'Number of RT clock edges in Saleae does NOT match that of IntegrationRois log!\n');
end

RT_match_by_frame = all(s.RT_preds == m.RT_preds, 2);
if all(RT_match_by_frame)
    cprintf('blue', '  RT predictions (LL/L/0/R/RR) in Saleae matches that of IntegrationRois log\n');
else
    s.frames_with_wrong_preds = find(~RT_match_by_frame);
    num_mismatched_frames = length(s.frames_with_wrong_preds);
    cprintf('red', '  Warning: RT predictions (LL/L/0/R/RR) in Saleae does NOT match that of IntegrationRois log (num mismatches=%d)!\n',...
        num_mismatched_frames);
end

% Compute the per-frame RT output time and delay
%------------------------------------------------------------
s.RT_output_time_by_frame = Inf * ones(s.num_frames, 1);
MR_time_by_frame = Inf * ones(s.num_frames, 1);
for k = 1:num_processed_frames
    frame_ind = m.RT_processed_frames(k);
    RT_clk_time = s.RT_clk_times(k);
    s.RT_output_time_by_frame(frame_ind) = RT_clk_time;

    % Find the first Matlab read that comes after the RT clock edge. This
    % is the Matlab read that "reads in" the RT calculation
    MR_ind = find(s.matlab_read_times > RT_clk_time, 1, 'first');
    if ~isempty(MR_ind)
        MR_time_by_frame(frame_ind) = s.matlab_read_times(MR_ind);
    end
end

% If a frame's RT output was dropped by ScanImage, then RT_delay_by_frame
% for that frame is Inf
s.RT_delay_by_frame = s.RT_output_time_by_frame - s.frame_times;

% MR_delay_by_frame measures the delay until the RT calculation is read in
% by a Matlab read. Note: Outside of trials, MR delays can be very long
s.MR_delay_by_frame = MR_time_by_frame - s.frame_times;

% Report RT latency stats
%------------------------------------------------------------
for k = 1:3
    num_frames_within_delay = sum(s.RT_delay_by_frame < k*s.frame_period);
    fprintf('  Number of frames processed within %d frame period: %d (%.1f%%)\n',...
        k, num_frames_within_delay, num_frames_within_delay/s.num_frames * 100.0);
end

nonInf_RT_delay_by_frame = s.RT_delay_by_frame(~isinf(s.RT_delay_by_frame));

avg_RT_delay = mean(nonInf_RT_delay_by_frame);
fprintf('  Average delay: %.1f ms (=%.3f frames)\n',...
    avg_RT_delay * 1e3, avg_RT_delay/s.frame_period);

max_RT_delay = max(nonInf_RT_delay_by_frame);
fprintf('  Maximum delay: %.1f ms (=%.3f frames)\n',...
    max_RT_delay * 1e3, max_RT_delay/s.frame_period);

% For each Matlab read, calculate the expected read value
%------------------------------------------------------------
RT_vals = s.RT_preds * [-2 -1 0 1 2]'; % Convert one-hot vec to value

matlab_read_vals = zeros(s.num_matlab_reads, 1);

% First, find the cumulative position at the time of each Matlab read
for k = 1:s.num_matlab_reads
    mr_time_k = s.matlab_read_times(k);
    RT_ind = find(s.RT_clk_times < mr_time_k, 1, 'last');
    matlab_read_vals(k) = sum(RT_vals(1:RT_ind));
end

% Next, compute the difference in the cumulative position between Matlab
% reads. This is because each Matlab read resets the counter.
for k = fliplr(2:s.num_matlab_reads) % The fliplr is important!
    matlab_read_vals(k) = matlab_read_vals(k) - matlab_read_vals(k-1);
end
matlab_read_vals(1) = 0;
s.matlab_read_vals = matlab_read_vals;