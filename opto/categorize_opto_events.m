function [laser_off_events, laser_on_events] = categorize_opto_events(event_times, laser_off, laser_on)

laser_off_events = ismember(event_times, laser_off);

num_lasers = length(laser_on);
laser_on_events = cell(1, num_lasers);
for l = 1:num_lasers
    laser_on_events{l} = ismember(event_times, laser_on{l});
end