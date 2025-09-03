function [behavior, info] = parse_onebox(source)
% Derived from 'ctxstr.parse_saleae'

if ~exist('source', 'var')
    file = dir('*.obx.bin');
    source = file(1).name;
end

% Define OneBox channels
encA_ch = 0;
encB_ch = 1;
us_ch = 2; % "Pump enable"
behavior_clock_ch = 3;
lick_ch = 4;

% Load data
%------------------------------------------------------------
fprintf('Loading %s into memory... ', source); tic;

path = '.';
meta = SGLX_readMeta.ReadMeta(source, path);
Fs = SGLX_readMeta.SampRate(meta); % Sampling rate
dataArray = SGLX_readMeta.ReadBin(0, inf, meta, source, path);

dw = 1;
dLineList = [encA_ch, encB_ch, us_ch, behavior_clock_ch, lick_ch];
digArray = SGLX_readMeta.ExtractDigital(dataArray, meta, dw, dLineList)';
num_samples = size(digArray, 1);

t = toc; fprintf('Done in %.1f seconds!\n', t);

% OneBox returns digital data at a constant sampling rate. We'll keep only
% the samples where at least one of the digital values changed. This is the
% way that Saleae stores digital data.

fprintf('Sparsifying OneBox data (this can take a few minutes)... '); tic;

keep_sample = false(num_samples, 1);
keep_sample(1) = true;

ref_sample = digArray(1, :);
for k = 2:num_samples
    curr_sample = digArray(k, :);
    if any(curr_sample ~= ref_sample)
        keep_sample(k) = true;
        ref_sample = curr_sample;
    end
end

times = 1/Fs * (0:num_samples-1)';
data = [times(keep_sample) double(digArray(keep_sample,:))];

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

dt = 0.05; % seconds, used for velocity estimation
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

% Next, determine the empirical distance threshold for reward
us_threshold = mean(cellfun(@(x) x(end,2), pos_by_trial));
fprintf('  On average, reward delivered after %.1f encoder clicks\n', us_threshold);

% Finally, determine an _approximate_ movement onset based on distance traveled
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
% TODO: In the future, work on get lick times from analysis of behavioral
% video rather than a direct lickometer measurement

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

% Save results to file
%   info.hw_params: Hardware parameters
%   info.saleae: Related to Saleae export
%   info.params: Parameters used to compute intermediate quantities
%                (e.g. velocity, reward response)
%------------------------------------------------------------
info.hw_params.cpr = cpr; % Encoder counts per rotation
info.hw_params.R = R; % radius of wheel (cm)
info.onebox.time_window = times([1 end])'; % seconds
info.onebox.Fs = Fs;
info.onebox.meta = meta;
info.params.velocity_dt = dt; % Used for velocity computation
info.params.movement_onset_threshold = movement_onset_threshold;
info.params.lick_response_window = lick_response_window; % seconds

save('ctxstr.mat', 'behavior', 'info');

end % parse_onebox
