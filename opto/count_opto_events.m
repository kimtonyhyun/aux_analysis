function [p1, p2] = count_opto_events(events, laser_off, laser_on)

num_events = length(events);
is_opto_event = zeros(num_events,1);

for k = 1:num_events
    event = events(k);
    is_opto_event(k) = ismember(event, laser_on);
end

num_opto_events = sum(is_opto_event);
num_nonopto_events = num_events - num_opto_events;

opto_frac = length(laser_on)/(length(laser_on)+length(laser_off));
p1 = binocdf(num_opto_events, num_events, opto_frac);
p2 = 1-p1;

% Report results
fprintf('Observed %d events:\n', num_events);
fprintf('  - %d events during opto ON\n', num_opto_events);
fprintf('  - %d events during opto OFF\n', num_nonopto_events);
fprintf('Opto fraction was %.1f%%. Under null hypothesis:\n', 100*opto_frac);
fprintf('  - Expected number of events during opto ON: %.1f\n', opto_frac*num_events);
fprintf('  - p-value of observing fewer than %d opto events: %.4f\n',...
    num_opto_events, p1);
fprintf('  - p-value of observing more than %d opto events: %.4f\n',...
    num_opto_events, p2);