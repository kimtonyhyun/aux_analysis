function [p_lower, p_upper] = count_opto_events(event_times, laser_off_frames, laser_on_frames)
% Compute the p-value of observed opto effect, by assuming a Poisson
% distribution of events with the rate determined by the firing over _both_
% laser-off and laser-on frames.

% Count the number of events that occur during provided 'laser_off_frames'
% or 'laser_on_frames'
num_opto_events = sum(ismember(event_times, laser_on_frames));
num_nonopto_events = sum(ismember(event_times, laser_off_frames));

num_events = num_opto_events + num_nonopto_events;

% If there are no events during the prescribed periods, then we can't
% perform any statistical tests. Return immediately.
if (num_events == 0)
    fprintf('Observed 0 events during specified periods!\n');
    p_lower = 0.5;
    p_upper = 0.5;
    return;
end

% Test whether the distribution of events between laser off and laser on
% periods is statistically anomalous. The null hypothesis is that the
% laser status has no influence on event distribution
opto_frac = length(laser_on_frames)/(length(laser_on_frames)+length(laser_off_frames));

% Under the null hypothesis, we expect the number of opto events to be
% proportional to the amount of time the laser was on
expected_num_opto_events = opto_frac * num_events; % Under null hypothesis
p_lower = poisscdf(num_opto_events, expected_num_opto_events);
p_upper = poisscdf(num_opto_events, expected_num_opto_events, 'upper');

% Report results
fprintf('Observed %d events total:\n', num_events);
fprintf('  - %d events during opto ON\n', num_opto_events);
fprintf('  - %d events during opto OFF\n', num_nonopto_events);
fprintf('Opto fraction was %.1f%%. Under null hypothesis:\n', 100*opto_frac);
fprintf('  - Expected number of events during opto ON: %.1f\n', opto_frac*num_events);
fprintf('  - p-value of observing %d or FEWER opto events: %.6f\n',...
    num_opto_events, p_lower);
fprintf('  - p-value of observing %d or MORE opto events: %.6f\n',...
    num_opto_events, p_upper);