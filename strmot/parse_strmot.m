% function [ctx, str, behavior, pos] = parse_strmot(source)

source = 'strmot.csv';

% Saleae channels
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

%%

% Parse behavioral data at full resolution
%------------------------------------------------------------

% Encoder
pos = parse_encoder(data, encA_ch, encB_ch);
cpr = 500; % clicks per rotation
R = 5.5; % cm, approximate effective radius on InnoWheel
pos(:,2) = 2*pi*R/cpr*pos(:,2); % Convert to cm
fprintf('Encoder: %.1f cm traveled over %.1f seconds\n', pos(end,2), pos(end,1));

% Rewards
us_times = find_pulses(data, us_ch);
% Each US event consists of two pulses. So skip every other pulse
us_times = us_times(1:2:end,1);
num_rewards = size(us_times,1);
fprintf('Detected %d rewards\n', num_rewards);

% Licks:
% Note: Can filter for lick durations
lick_times = find_pulses(data, lick_ch);
lick_times = lick_times(:,1);

% Behavior camera
behavior_frame_times = find_edges(data, behavior_clock_ch);
fprintf('Found %d behavior frames at %.1f FPS\n',...
    length(behavior_frame_times), 1/(behavior_frame_times(2)-behavior_frame_times(1)));

% Package for output
behavior.frame_times = behavior_frame_times;
behavior.pos = pos;
behavior.us_times = us_times;
behavior.lick_times = lick_times;

%%

ctx_frame_times = find_edges(data, ctx_clock_ch);
num_ctx_frames = length(ctx_frame_times);
fprintf('Found %d ctx frames\n', num_ctx_frames);

str_frame_times = find_edges(data, str_clock_ch);
num_str_frames = length(str_frame_times);
fprintf('Found %d str frames\n', num_str_frames);

if (ctx_frame_times(1) < str_frame_times(1))
    fprintf('%d ctx frames precede the first str frame\n',...
        sum(ctx_frame_times < str_frame_times(1)));
else
    fprintf('%d str frames precede the first ctx frame\n',...
        sum(str_frame_times < ctx_frame_times(1)));
end