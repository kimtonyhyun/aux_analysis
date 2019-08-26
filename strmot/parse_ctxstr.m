function [ctx, str, behavior, info] = parse_ctxstr(source)
% Todo: Handle forced running signal

% Define Saleae channels
encA_ch = 0;
encB_ch = 1;
us_ch = 2; % "Pump enable"
lick_ch = 3;
behavior_clock_ch = 4;
ctx_clock_ch = 6;
str_clock_ch = 7;

% Load data
%------------------------------------------------------------
fprintf('Loading Saleae data into memory... '); tic;
data = load(source);
times = data(:,1);
t = toc; fprintf('Done in %.1f seconds!\n', t);

% Parse behavioral data at full resolution
%------------------------------------------------------------
% Encoder
pos = parse_encoder(data, encA_ch, encB_ch);
cpr = 500; % clicks per rotation
R = 5.5; % cm, approximate effective radius on InnoWheel
pos(:,2) = 2*pi*R/cpr*pos(:,2); % Convert to cm
fprintf('Encoder: %.1f cm traveled over %.1f seconds\n', pos(end,2), pos(end,1));

% Compute velocity
dt = 0.25; % seconds, used for velocity estimation
t = dt:dt:(times(end)-dt);
pos2 = interp1(pos(:,1), pos(:,2), t+dt/2);
pos1 = interp1(pos(:,1), pos(:,2), t-dt/2);
velocity = (pos2-pos1)/dt; % cm/s
fprintf('Computed velocity over dt=%.3f second windows\n', dt);

% Rewards
us_times = find_pulses(data, us_ch);
% Each US event consists of two pulses. So skip every other pulse
us_times = us_times(1:2:end,1);
% First reward is an automatic one at the beginning of session
us_times = us_times(2:end);
num_rewards = size(us_times,1);
fprintf('Detected %d rewards (skipped first reward)\n', num_rewards);

% Licks:
% Note: Can filter here for lick durations
lick_times = find_pulses(data, lick_ch);
lick_times = lick_times(:,1);

% Behavior camera
behavior_frame_times = find_edges(data, behavior_clock_ch);
T_beh = mean(diff(behavior_frame_times));
fprintf('Found %d behavior frames at %.2f FPS\n',...
    length(behavior_frame_times), 1/T_beh);

% Package for output
behavior.frame_times = behavior_frame_times;
behavior.position = pos;
behavior.velocity = [t' velocity'];
behavior.us_times = us_times;
behavior.lick_times = lick_times;

% Parse imaging clocks
%------------------------------------------------------------
ctx_frame_times = find_edges(data, ctx_clock_ch);
num_ctx_frames = length(ctx_frame_times);
T_ctx = mean(diff(ctx_frame_times));
fprintf('Found %d ctx frames at %.2f FPS\n', num_ctx_frames, 1/T_ctx);

str_frame_times = find_edges(data, str_clock_ch);
num_str_frames = length(str_frame_times);
T_str = mean(diff(str_frame_times));
fprintf('Found %d str frames at %.2f FPS\n', num_str_frames, 1/T_str);

if (ctx_frame_times(1) < str_frame_times(1))
    fprintf('%d ctx frames precede the first str frame\n',...
        sum(ctx_frame_times < str_frame_times(1)));
else
    fprintf('%d str frames precede the first ctx frame\n',...
        sum(str_frame_times < ctx_frame_times(1)));
end

% Package for output
ctx.frame_times = ctx_frame_times;
ctx.us = assign_edge_to_frames(us_times, ctx_frame_times);
ctx.lick = assign_edge_to_frames(lick_times, ctx_frame_times);
ctx.velocity = interp1(t, velocity, ctx_frame_times);

str.frame_times = str_frame_times;
str.us = assign_edge_to_frames(us_times, str_frame_times);
str.lick = assign_edge_to_frames(lick_times, str_frame_times);
str.velocity = interp1(t, velocity, str_frame_times);

% Save results to file
%------------------------------------------------------------
info.dt = dt; % Used for velocity computation
info.recording_length = times(end);

save('ctxstr.mat', 'ctx', 'str', 'behavior', 'info');

end % parse_ctxstr