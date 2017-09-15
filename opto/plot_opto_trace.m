function plot_opto_trace(trace, laser_off, laser_on)

laser_off_segments = frame_list_to_segments(laser_off);
num_off_segments = size(laser_off_segments,1);

for k = 1:num_off_segments
    laser_off_segment = laser_off_segments(k,:);
    x = laser_off_segment(1):laser_off_segment(2);
    plot(x, trace(x), 'k');
    hold on;
end

laser_on_segments = frame_list_to_segments(laser_on);
num_on_segments = size(laser_on_segments,1);

for k = 1:num_on_segments
    laser_on_segment = laser_on_segments(k,:);
    x = laser_on_segment(1):laser_on_segment(2);
    plot(x, trace(x), 'r');
end
hold off;

% Formatting
xlim([1 length(trace)]);
M = max(trace);
m = min(trace);
ylim([m M] + 0.1*(M-m)*[-1 1]);
grid on;