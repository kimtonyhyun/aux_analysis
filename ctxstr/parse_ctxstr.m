function [ctx, str, behavior, info] = parse_ctxstr(source)

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
cpr = 500; % clicks per rotation
pos = parse_encoder(data, encA_ch, encB_ch); % [time enc_count]
fprintf('Encoder: %.1f rotations over %.1f seconds (%.1f minutes)\n',...
    pos(end,2)/cpr, pos(end,1), pos(end,1)/60);

% Velocity
R = 5.5; % cm, approximate effective radius on InnoWheel FIXME
pos_cm = 2*pi*R/cpr*pos(:,2); % Convert to distance (cm)

dt = 0.25; % seconds, used for velocity estimation
t = dt:dt:(times(end)-dt);
pos2 = interp1(pos(:,1), pos_cm, t+dt/2);
pos1 = interp1(pos(:,1), pos_cm, t-dt/2);
velocity = (pos2-pos1)/dt; % cm/s
fprintf('Computed velocity over dt=%.3f second windows\n', dt);

% Rewards
us_times = find_edges(data, us_ch);

% Determine the number of pulses per reward. We assume pulses that occur in
% a rapid (sub-second) succession are part of a single reward
num_pulses_per_reward = sum((us_times - us_times(1)) < 0.1);
fprintf('Detected %d pulses per reward\n', num_pulses_per_reward);
us_times = us_times(1:num_pulses_per_reward:end);

% Movement onset
% Onset defined by distance traveled towards reward threshold

% First, determine the reward threshold from the position data. To do this,
% split the position trace across individual trials, defined by the US.
num_rewards = length(us_times);
trial_inds = zeros(num_rewards,1);
for k = 1:num_rewards
    us_time = us_times(k);
    trial_inds(k) = find(pos(:,1) > us_time, 1, 'first');
end

% The first US is a freebie at the beginning of each session, unrelated to
% animal movement.
us_times = us_times(2:end);
num_rewards = num_rewards-1;
fprintf('Detected %d rewards, excluding the first (free) reward\n', num_rewards);

pos_by_trial = cell(num_rewards, 1);
for k = 1:num_rewards
    inds_k = trial_inds(k):trial_inds(k+1)-1;
    pos_k = pos(inds_k,:);
    pos_k(:,2) = pos_k(:,2) - pos_k(1,2); % "Reset" position after each US
    pos_by_trial{k} = pos_k;
end

% Next, determine the empirical distance threhsold for reward
us_threshold = mean(cellfun(@(x) x(end,2), pos_by_trial));
fprintf('On average, reward delivered after %.1f encoder clicks\n', us_threshold);

% Finally, determine the movement onset based on distance traveled
movement_onset_threshold = 0.2;
movement_onset_times = zeros(num_rewards,1);
for k = 1:num_rewards
    pos_k = pos_by_trial{k};
    ind = find(pos_k(:,2) > movement_onset_threshold * us_threshold, 1, 'first');
    movement_onset_times(k) = pos_k(ind,1);
end

% Licks:
% Note: Can filter here for lick durations
lick_times = find_edges(data, lick_ch);

% Lick response: Is there a detected lick within 1 s of water reward?
lick_response_window = 1;
lick_responses = zeros(num_rewards, 1);
for k = 1:num_rewards
    us_time = us_times(k);
    ind = find(lick_times >= us_time, 1, 'first');
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
behavior.position.cont = pos; % [time encoder-counts]
behavior.position.by_trial = pos_by_trial; % Can be converted into a regular matrix by: pos_wrapped = cat(1, behavior.position.by_trial{:});
behavior.position.us_threshold = us_threshold;
behavior.velocity = [t' velocity']; % [time cm/s]
behavior.movement_onset_times = movement_onset_times;
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
%   info.hw_params: Hardware parameters
%   info.saleae: Related to Saleae export
%   info.params: Parameters used to compute intermediate quantities
%                (e.g. velocity, reward response)
%------------------------------------------------------------
info.hw_params.cpr = cpr; % Encoder counts per rotation
info.hw_params.R = R; % radius of wheel (cm)
info.saleae.time_window = times([1 end]); % seconds
info.params.velocity_dt = dt; % Used for velocity computation
info.params.movement_onset_threshold = movement_onset_threshold;
info.params.lick_response_window = lick_response_window; % seconds

save('ctxstr.mat', 'ctx', 'str', 'behavior', 'info');

end % parse_ctxstr

function generate_pmtext(outname, reward_frames, responses, imaging_fps, max_frames)
    % Trial frames: [Trial-start Motion-onset US Trial-end]
    %   Trial-start: 5 s prior to US
    %   Motion-onset
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