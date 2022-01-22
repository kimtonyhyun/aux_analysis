function [ctx, str, behavior, info] = parse_saleae(source)

if ~exist('source', 'var')
    source = 'behavior.csv';
end

% Define Saleae channels
encA_ch = 0;
encB_ch = 1;
us_ch = 2; % "Pump enable"
lick_ch = 3;
behavior_clock_ch = 4;
opto_shutter_ch = 5;
ctx_clock_ch = 6;
str_clock_ch = 7;

ctx_fps = 30;
str_fps = 45;

% Load data
%------------------------------------------------------------
fprintf('Loading Saleae data into memory... '); tic;
data = load(source);
times = data(:,1);
t = toc; fprintf('Done in %.1f seconds!\n', t);

% Parse behavioral data at full resolution
%------------------------------------------------------------

% Behavior camera
% In principle, the 'behavior_recording_duration' is the length of time
% over which the task is active (i.e. period of time during which the mouse
% can earn rewards for movement).
behavior_frame_times = find_edges(data, behavior_clock_ch);
behavior_recording_duration = behavior_frame_times(end) - behavior_frame_times(1);
T_beh = mean(diff(behavior_frame_times));
fprintf('Behavior camera:\n  Found %d frames at %.2f FPS\n  Total length of behavioral recording: %.1f s (=%.1f min)\n',...
    length(behavior_frame_times), 1/T_beh, behavior_recording_duration, behavior_recording_duration/60);

% Encoder
cpr = 500; % clicks per rotation
pos = parse_encoder(data, encA_ch, encB_ch); % [time enc_count]
fprintf('Encoder:\n  Logged %.1f rotations over %.1f seconds\n',...
    pos(end,2)/cpr, pos(end,1));

% Velocity
R = 14.5/2; % cm, measured 2020 Nov 17
pos_cm = 2*pi*R/cpr*pos(:,2); % Convert to distance (cm)

dt = 0.25; % seconds, used for velocity estimation
t = dt:dt:(times(end)-dt);
pos2 = interp1(pos(:,1), pos_cm, t+dt/2);
pos1 = interp1(pos(:,1), pos_cm, t-dt/2);
velocity = (pos2-pos1)/dt; % cm/s
fprintf('  Computed velocity over dt=%.3f second windows\n', dt);

% Rewards
us_times = find_edges(data, us_ch);

% Determine the number of pulses per reward. We assume pulses that occur in
% a rapid (sub-second) succession are part of a single reward
num_pulses_per_reward = sum((us_times - us_times(1)) < 0.1);
fprintf('Rewards:\n  Detected %d solenoid pulses per reward\n', num_pulses_per_reward);
us_times = us_times(1:num_pulses_per_reward:end);
num_rewards = length(us_times);

trial_start_times = us_times(1:end-1);
trial_durations = diff(us_times);

% Movement onset
% Onset defined by distance traveled towards reward threshold

% First, determine the reward threshold from the position data. To do this,
% split the position trace across individual trials, defined by the US.
inds = zeros(num_rewards,1);
for k = 1:num_rewards
    us_time = us_times(k);
    inds(k) = find(pos(:,1) > us_time, 1, 'first');
end

% The first US is a freebie at the beginning of each session, unrelated to
% animal movement.
us_times = us_times(2:end);
num_rewards = num_rewards-1;
fprintf('  Detected %d rewards, excluding the first (free) reward\n', num_rewards);

pos_by_trial = cell(num_rewards, 1);
for k = 1:num_rewards
    inds_k = inds(k):inds(k+1)-1;
    pos_k = pos(inds_k,:);
    pos_k(:,2) = pos_k(:,2) - pos_k(1,2); % "Reset" position after each US
    pos_by_trial{k} = pos_k;
end

% Next, determine the empirical distance threhsold for reward
us_threshold = mean(cellfun(@(x) x(end,2), pos_by_trial));
fprintf('  On average, reward delivered after %.1f encoder clicks\n', us_threshold);

% Finally, determine the movement onset based on distance traveled
movement_onset_threshold = 0.1;
movement_onset_times = zeros(num_rewards,1);
for k = 1:num_rewards
    pos_k = pos_by_trial{k};
    ind = find(pos_k(:,2) > movement_onset_threshold * us_threshold, 1, 'first');
    if ~isempty(ind)
        movement_onset_times(k) = pos_k(ind,1);
    else
        % This condition seems to occur when there are glitches in the pump
        % enable signal, causing the parser to think that there are "extra"
        % trials.
        cprintf('blue', 'Warning: Movement onset not detected for Trial %d\n', k);
        cprintf('blue', 'Trial %d duration is %.3f s.\n',...
            k, pos_k(end,1) - pos_k(1,1));
        cprintf('blue', 'If this duration is abnormally short, try applying a 0.1 ms glitch filter on the "pump enable" channel before Saleae export\n');
        movement_onset_times(k) = NaN;
    end
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
fprintf('  Lick responses in %d out of %d rewards (%.1f%% hit rate, using %.1f second response window)\n',...
    sum(lick_responses), num_rewards, sum(lick_responses)/num_rewards*100, lick_response_window);

% Parse opto stats
opto_periods = find_pulses(data, opto_shutter_ch);

opto_duration = sum(diff(opto_periods, [], 2));
nonopto_duration = (behavior_recording_duration - opto_duration);

opto_duration = opto_duration/60; % min
nonopto_duration = nonopto_duration/60;

num_opto_rewards = 0;
num_nonopto_rewards = 0;
for k = 1:num_rewards
    us_time = us_times(k);
    if any((opto_periods(:,1) < us_time) & (us_time < opto_periods(:,2)))
        num_opto_rewards = num_opto_rewards + 1;
    else
        num_nonopto_rewards = num_nonopto_rewards + 1;
    end
end

fprintf('Opto:\n  Found %d opto periods\n', size(opto_periods, 1));
fprintf('  %d rewards occur during opto (%1.f min; %.1f rewards/min)\n',...
    num_opto_rewards, opto_duration, num_opto_rewards/opto_duration);
fprintf('  %d rewards occur during non-opto (%.1f min; %.1f rewards/min)\n',...
    num_nonopto_rewards, nonopto_duration, num_nonopto_rewards/nonopto_duration);

% Package for output
behavior.frame_times = behavior_frame_times;
behavior.position.cont = pos; % [time encoder-counts]
behavior.position.by_trial = pos_by_trial; % Can be converted into a regular matrix by: pos_wrapped = cat(1, behavior.position.by_trial{:});
behavior.position.us_threshold = us_threshold;
behavior.velocity = [t' velocity']; % [time cm/s]
behavior.trial_start_times = trial_start_times;
behavior.movement_onset_times = movement_onset_times;
behavior.us_times = us_times;
behavior.trial_durations = trial_durations;
behavior.lick_times = lick_times;
behavior.lick_responses = logical(lick_responses);
behavior.opto_periods = opto_periods;

% Parse imaging clocks
%------------------------------------------------------------

ctx_frame_times = find_edges(data, ctx_clock_ch);
num_ctx_frames = length(ctx_frame_times);

str_frame_times = find_edges(data, str_clock_ch);
num_str_frames = length(str_frame_times);

% Find USes that occured during imaging
if (num_ctx_frames == 0) && (num_str_frames == 0) % Behavior only
    imaging_start_time = Inf;
    imaging_end_time = -Inf;
elseif (num_str_frames == 0) % Ctx-only imaging
    imaging_start_time = ctx_frame_times(1);
    imaging_end_time = ctx_frame_times(end);
elseif (num_ctx_frames == 0) % Str-only imaging
    imaging_start_time = str_frame_times(1);
    imaging_end_time = str_frame_times(end);
else
    % Dual-site imaging. Note that trials are exported only if the trial
    % is captured by _both_ ctx and str recordings.
    imaging_start_time = max(ctx_frame_times(1), str_frame_times(1));
    imaging_end_time = min(ctx_frame_times(end), str_frame_times(end));
end

first_imaged_trial = find(trial_start_times > imaging_start_time, 1, 'first');
last_imaged_trial = find(us_times < imaging_end_time, 1, 'last');
imaged_trials = first_imaged_trial:last_imaged_trial;
fprintf('%d of %d trials (rewards) fully contained in the imaging period\n', length(imaged_trials), num_rewards);

imaged_trial_start_times = trial_start_times(imaged_trials);
imaged_movement_onset_times = movement_onset_times(imaged_trials);
imaged_us_times = us_times(imaged_trials);
imaged_lick_responses = lick_responses(imaged_trials);

% Ctx
if num_ctx_frames == 0
    cprintf('Blue', 'Warning: Ctx frame clock NOT detected\n');
    ctx = [];
else
    T_ctx = mean(diff(ctx_frame_times));
    fprintf('Found %d ctx frames at %.2f FPS\n', num_ctx_frames, 1/T_ctx);
    
    ctx.frame_times = ctx_frame_times;
    
    ctx.trial_start = assign_edge_to_frames(imaged_trial_start_times, ctx_frame_times);
    ctx_trial_start_frames = find(ctx.trial_start);
    
    ctx.movement_onset = assign_edge_to_frames(imaged_movement_onset_times, ctx_frame_times);
    ctx_movement_onset_frames = find(ctx.movement_onset);
    
    ctx.us = assign_edge_to_frames(imaged_us_times, ctx_frame_times);
    ctx_us_frames = find(ctx.us);
    
    ctx.lick = assign_edge_to_frames(lick_times, ctx_frame_times);
    ctx.velocity = interp1(t, velocity, ctx_frame_times);  
    
    generate_pmtext('ctx.txt', ctx_trial_start_frames, ctx_movement_onset_frames, ctx_us_frames, imaged_lick_responses, ctx_fps, num_ctx_frames);
end

% Str
if num_str_frames == 0
    cprintf('Blue', 'Warning: Str frame clock NOT detected\n');
    str = [];
else
    T_str = mean(diff(str_frame_times));
    fprintf('Found %d str frames at %.2f FPS\n', num_str_frames, 1/T_str);
    
    str.frame_times = str_frame_times;
    
    str.trial_start = assign_edge_to_frames(imaged_trial_start_times, str_frame_times);
    str_trial_start_frames = find(str.trial_start);
    
    str.movement_onset = assign_edge_to_frames(imaged_movement_onset_times, str_frame_times);
    str_movement_onset_frames = find(str.movement_onset);
    
    str.us = assign_edge_to_frames(imaged_us_times, str_frame_times);
    str_us_frames = find(str.us);
    
    str.lick = assign_edge_to_frames(lick_times, str_frame_times);
    str.velocity = interp1(t, velocity, str_frame_times);

    generate_pmtext('str.txt', str_trial_start_frames, str_movement_onset_frames, str_us_frames, imaged_lick_responses, str_fps, num_str_frames);
end

% Save results to file
%   info.hw_params: Hardware parameters
%   info.saleae: Related to Saleae export
%   info.params: Parameters used to compute intermediate quantities
%                (e.g. velocity, reward response)
%------------------------------------------------------------
info.hw_params.cpr = cpr; % Encoder counts per rotation
info.hw_params.R = R; % radius of wheel (cm)
info.hw_params.ctx_fps = ctx_fps;
info.hw_params.str_fps = str_fps;
info.saleae.time_window = times([1 end])'; % seconds
info.params.velocity_dt = dt; % Used for velocity computation
info.params.movement_onset_threshold = movement_onset_threshold;
info.params.lick_response_window = lick_response_window; % seconds
info.imaged_trials = imaged_trials;

save('ctxstr.mat', 'ctx', 'str', 'behavior', 'info');

end % parse_ctxstr

function generate_pmtext(outname, trial_start_frames, movement_onset_frames, reward_frames, responses, imaging_fps, max_frames)
    fid = fopen(outname, 'w');
    for k = 1:length(reward_frames)
        if responses(k)
            pm_filler = 'east north north 10.0'; % "Correct" trial
        else
            pm_filler = 'east north south 10.0'; % "Incorrect" trial
        end
        
        tsf = trial_start_frames(k);
        mof = movement_onset_frames(k);
        rf = reward_frames(k);
        
        % Trial frames. Notes:
        %   - We provide a 2 s buffer after reward.
        %   - It's possible that the 2 s buffer is not fully contained in
        %     the imaging period, for the last trial.
        tf = [tsf mof rf rf+2*imaging_fps];
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