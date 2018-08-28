clear all; close all;

%%

% Format: [Current1 Current2 Xpos Ypos RobotState Lick Laser Frame1 Frame2 Solenoid TrialToggle]
%   Sampled at 200 Hz
data = dlmread('2w_082718.csv', '\t');
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

% We seem to get an "extra" frame when the frame counter resets at the end
% of a recording
num_frames = num_frames - 1;

frame_samples = frame_samples(1:num_frames);

%% Sample solenoid and lickometer traces.
reward = zeros(num_frames, 1);
lick = zeros(num_frames, 1);

% Note that the solenoid / lick pulses can be shorter than the microscope
% frame clock.
for k = 1:num_frames-1
    solenoid_segment = data(frame_samples(k):frame_samples(k+1), 10);
    reward(k) = any(solenoid_segment>0);
    
    lick_segment = data(frame_samples(k):frame_samples(k+1), 6);
    lick(k) = any(lick_segment>0);
end

%% Resample behavior on the rising edge of frame counter

% Format: [Xpos Ypos Lick Solenoid TrialToggle]
behavior.pos = data(frame_samples, [3 4]);
behavior.trial_toggle = data(frame_samples, 11);

behavior.lick = lick;
behavior.reward = reward;

%%

ax1 = subplot(2,1,1);
yyaxis left;
plot(behavior.pos(:,2));
ylabel('y position');
ylim([-1 10]);
yyaxis right;
plot(reward, 'r');
ylabel('solenoid');
ylim([-1 2]);

ax2 = subplot(2,1,2);
plot(behavior.trial_toggle);
ylabel('trial toggle');
xlabel('Frame');
ylim([-1 2]);

linkaxes([ax1 ax2], 'x');
xlim([1 num_frames]);

%% Enumerate successful trials
reward_frames = [];

% Find positive edges of the reward signal
reward_prev = reward(1);
for k = 2:num_frames
    reward_curr = reward(k);
    if (~reward_prev && reward_curr) % pos edge
        reward_frames = [reward_frames k]; %#ok<AGROW>
    end
    reward_prev = reward_curr;
end

% Omit the first and last trials, in case we only have imaging data over
% only a part of those trials.
reward_frames = reward_frames(2:end-1);
num_trials = length(reward_frames);

load('opto.mat');
is_opto_trial = zeros(num_trials,1);

trial_frame_indices = zeros(num_trials, 4);
for k = 1:num_trials
    reward_frame = reward_frames(k);
    trial_frame_indices(k,1) = reward_frame - 60;
    trial_frame_indices(k,2) = reward_frame - 30;
    trial_frame_indices(k,3) = reward_frame;
    trial_frame_indices(k,4) = reward_frame + 30;
    
    is_opto_trial(k) = ~ismember(reward_frame, laser_off);   
end

write_reachbot(trial_frame_indices, is_opto_trial);