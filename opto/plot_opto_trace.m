function plot_opto_trace(trace, laser_off, laser_on)
% Plots 'trace' where contiguous segments of frames in `laser_off` and
% `laser_on` are colored differently.
%
% `laser_on` may be a cell, indicating frames for which different sets of
% lasers were active.
%
% Example usage:
%   plot_opto_trace(mu, laser_off, laser_on);
%   plot_opto_trace(mu, laser_off, {laser1_on, laser2_on});

laser_off_segments = frame_list_to_segments(laser_off);
num_off_segments = size(laser_off_segments,1);

for k = 1:num_off_segments
    laser_off_segment = laser_off_segments(k,:);
    x = laser_off_segment(1):laser_off_segment(2);
    plot(x, trace(x), 'k');
    hold on;
end

if ~iscell(laser_on)
    laser_on = {laser_on};
end

colors = 'rmg';
num_lasers = length(laser_on);
for l = 1:num_lasers
    color = colors(mod(l-1,length(colors))+1);
    laser_on_segments = frame_list_to_segments(laser_on{l});
    num_on_segments = size(laser_on_segments,1);

    for k = 1:num_on_segments
        laser_on_segment = laser_on_segments(k,:);
        x = laser_on_segment(1):laser_on_segment(2);
        plot(x, trace(x), color);
    end
end
hold off;

% Formatting
xlim([1 length(trace)]);
M = max(trace);
m = min(trace);
ylim([m M] + 0.1*(M-m)*[-1 1]);
grid on;