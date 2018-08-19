clear all;

% Format: [Current1 Current2 Xpos Ypos RobotState Lick Laser Frame1 Frame2 Solenoid TrialToggle]
%   Sampled at 200 Hz
data = dlmread('2w-081518.csv', '\t');
num_samples = size(data, 1);

%% Process frame counter
frame_counter = data(:,9);

% Frame counter stored as int16 and can overflow. Unwrap negative
% increments in counter.
delta = diff(frame_counter);
overflows = find(delta<0);
for of = overflows
    frame_counter(of+1:end) = frame_counter(of+1:end) - ...
        (frame_counter(of+1)-frame_counter(of)) + 1;
end

%% Sample data on rising edge of frame counter
frame_samples = zeros(num_samples,1);
num_frames = 0;

frame_counter_prev = frame_counter(1);
for k = 2:num_samples
    frame_counter_curr = frame_counter(k);
    if ((frame_counter_curr - frame_counter_prev) == 1)
        num_frames = num_frames + 1;
        frame_samples(num_frames) = k;
    end
    frame_counter_prev = frame_counter_curr;
end
frame_samples = frame_samples(1:num_frames);

%% Sample solenoid and lickometer traces.
solenoid = zeros(num_frames, 1);
lick = zeros(num_frames, 1);

% Note that the solenoid / lick pulses can be shorter than the microscope
% frame clock.
for k = 1:num_frames-1
    solenoid_segment = data(frame_samples(k):frame_samples(k+1), 10);
    solenoid(k) = any(solenoid_segment>0);
    
    lick_segment = data(frame_samples(k):frame_samples(k+1), 6);
    lick(k) = any(lick_segment>0);
end

%% Resample behavior on the rising edge of frame counter

% Format: [Xpos Ypos Lick Solenoid TrialToggle]
behavior.pos = data(frame_samples, [3 4]);
behavior.trial_toggle = data(frame_samples, 11);

behavior.lick = lick;
behavior.reward = solenoid;

%%

ax1 = subplot(2,1,1);
yyaxis left;
plot(behavior.pos(:,2));
ylabel('y position');
ylim([-1 10]);
yyaxis right;
plot(solenoid, 'r');
ylabel('solenoid');
ylim([-1 2]);

ax2 = subplot(2,1,2);
plot(behavior.trial_toggle);
ylabel('trial toggle');
xlabel('Frame');
ylim([-1 2]);

linkaxes([ax1 ax2], 'x');
xlim([1 num_frames]);