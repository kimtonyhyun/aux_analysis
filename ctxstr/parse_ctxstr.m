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
pos = parse_encoder(data, encA_ch, encB_ch); % [time enc_count]
cpr = 500; % clicks per rotation
R = 5.5; % cm, approximate effective radius on InnoWheel
pos(:,2) = 2*pi*R/cpr*pos(:,2); % Convert to cm
fprintf('Encoder: %.1f cm traveled over %.1f seconds (%.1f minutes)\n',...
    pos(end,2), pos(end,1), pos(end,1)/60);

% Compute velocity
dt = 0.25; % seconds, used for velocity estimation
t = dt:dt:(times(end)-dt);
pos2 = interp1(pos(:,1), pos(:,2), t+dt/2);
pos1 = interp1(pos(:,1), pos(:,2), t-dt/2);
velocity = (pos2-pos1)/dt; % cm/s
fprintf('Computed velocity over dt=%.3f second windows\n', dt);

% Rewards
us_times = find_pulses(data, us_ch);
% Determine the number of pulses per reward. We assume pulses that occur in
% a rapid (sub-second) succession are part of a single reward
num_pulses_per_reward = sum((us_times(:,1) - us_times(1,1)) < 0.1);
fprintf('Detected %d pulses per reward\n', num_pulses_per_reward);
% Each US event consists of two pulses. So skip every other pulse
us_times = us_times(1:num_pulses_per_reward:end,1);
% First reward is an automatic one at the beginning of session
us_times = us_times(2:end);
num_rewards = size(us_times,1);
fprintf('Detected %d rewards, omitting the first (free) reward\n', num_rewards);

% Licks:
% Note: Can filter here for lick durations
lick_times = find_pulses(data, lick_ch); % [Rise_time Fall_time]
lick_times = lick_times(:,1);

% Lick response: Is there a detected lick within 1 s of water reward?
lick_response_window = 1;
lick_responses = zeros(num_rewards, 1);
for k = 1:num_rewards
    us_time = us_times(k);
    ind = find(lick_times > us_time, 1, 'first');
    if ~isempty(ind)
        lick_time = lick_times(ind); % Timing of first lick after k-th US
        if (lick_time - us_time < lick_response_window)
            lick_responses(k) = 1;
        end
    end
end
fprintf('Lick responses in %d out of %d rewards (%.1f%% hit rate, using %.1f second response window)\n',...
    sum(lick_responses), num_rewards, sum(lick_responses)/num_rewards*100, lick_response_window);

% Behavior camera
behavior_frame_times = find_edges(data, behavior_clock_ch);
T_beh = mean(diff(behavior_frame_times));
fprintf('Found %d behavior frames at %.2f FPS\n',...
    length(behavior_frame_times), 1/T_beh);

% Package for output
behavior.frame_times = behavior_frame_times;
behavior.position = pos;
behavior.velocity = [t' velocity']; % [time cm/s]
behavior.us_times = us_times;
behavior.lick_times = lick_times;
behavior.lick_responses = lick_responses;

% Parse imaging clocks
%------------------------------------------------------------

% Ctx
ctx_frame_times = find_edges(data, ctx_clock_ch);
num_ctx_frames = length(ctx_frame_times);

if num_ctx_frames == 0
    cprintf('Blue', 'Warning: Ctx frame clock NOT detected\n');
    ctx = [];
else
    T_ctx = mean(diff(ctx_frame_times));
    fprintf('Found %d ctx frames at %.2f FPS\n', num_ctx_frames, 1/T_ctx);
    
    ctx.frame_times = ctx_frame_times;
    [ctx.us, ctx.first_reward_idx] = assign_edge_to_frames(us_times, ctx_frame_times);
    ctx.lick = assign_edge_to_frames(lick_times, ctx_frame_times);
    ctx.velocity = interp1(t, velocity, ctx_frame_times);

    num_rewards_in_ctx_movie = sum(ctx.us);
    lick_responses_ctx = lick_responses(ctx.first_reward_idx:ctx.first_reward_idx+num_rewards_in_ctx_movie-1);
    fprintf('%d rewards occur during the ctx movie, ', num_rewards_in_ctx_movie);
    fprintf('starting from reward #%d\n', ctx.first_reward_idx);
    
    generate_pmtext('ctx.txt', find(ctx.us), lick_responses_ctx, 30, num_ctx_frames); % FIXME: Hard-coded FPS
end

% Str
str_frame_times = find_edges(data, str_clock_ch);
num_str_frames = length(str_frame_times);

if num_str_frames == 0
    cprintf('Blue', 'Warning: Str frame clock NOT detected\n');
    str = [];
else
    T_str = mean(diff(str_frame_times));
    fprintf('Found %d str frames at %.2f FPS\n', num_str_frames, 1/T_str);
    
    str.frame_times = str_frame_times;
    [str.us, str.first_reward_idx] = assign_edge_to_frames(us_times, str_frame_times);
    str.lick = assign_edge_to_frames(lick_times, str_frame_times);
    str.velocity = interp1(t, velocity, str_frame_times);

    num_rewards_in_str_movie = sum(str.us);
    lick_responses_str = lick_responses(str.first_reward_idx:str.first_reward_idx+num_rewards_in_str_movie-1);
    fprintf('%d rewards occur during the str movie, ', num_rewards_in_str_movie);
    fprintf('starting from reward #%d\n', str.first_reward_idx);
    
    generate_pmtext('str.txt', find(str.us), lick_responses_str, 45, num_str_frames);
end

if (num_ctx_frames > 0) && (num_str_frames > 0)
    if (ctx_frame_times(1) < str_frame_times(1))
        fprintf('%d ctx frames precede the first str frame\n',...
            sum(ctx_frame_times < str_frame_times(1)));
    else
        fprintf('%d str frames precede the first ctx frame\n',...
            sum(str_frame_times < ctx_frame_times(1)));
    end
end

% Save results to file
%------------------------------------------------------------
info.cpr = cpr; % Encoder counts per rotation
info.R = R; % radius of wheel (cm)
info.saleae_time_window = times([1 end]); % seconds
info.dt = dt; % Used for velocity computation
info.lick_response_window = lick_response_window; % seconds
info.recording_length = times(end);

save('ctxstr.mat', 'ctx', 'str', 'behavior', 'info');

end % parse_ctxstr

function generate_pmtext(outname, reward_frames, responses, imaging_fps, max_frames)
    frame_offsets = imaging_fps * [-5 -1 0 5];
    fid = fopen(outname, 'w');
    for k = 1:length(reward_frames)
        if responses(k)
            pm_filler = 'east north north 10.0'; % "Correct" trial
        else
            pm_filler = 'east north south 10.0'; % "Incorrect" trial
        end
        rf = reward_frames(k);
        tf = rf + frame_offsets; % "trial frames"
        if (tf(1) > 0) && (tf(4) < max_frames)
            fprintf(fid, '%s %d %d %d %d\n', pm_filler,...
                tf(1), tf(2), tf(3), tf(4));
        else
            fprintf('  Warning: In "%s", skipped Trial %d because trial window not fully captured by recording\n',...
                outname, k);
        end
    end
    fclose(fid);
end % generate_text