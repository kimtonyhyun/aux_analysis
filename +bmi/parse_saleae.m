source = 'behavior.csv';

% Define Saleae channels
encA_ch = 0;
encB_ch = 1;
us_ch = 2; % "Pump enable"
lick_ch = 3;
behavior_clock_ch = 4;
screen_ttl_ch = 5;
ctx_clock_ch = 6;
str_clock_ch = 7;

% Load data
%------------------------------------------------------------
fprintf('Loading Saleae data into memory... '); tic;
data = load(source);
times = data(:,1);
t = toc; fprintf('Done in %.1f seconds!\n', t);

%%

% Screen TTL times. Format: [on-time off-time]
screen_times = find_pulses(data, screen_ttl_ch);
num_trials = size(screen_times, 1);

% Encoder
cpr = 1024; % clicks per rotation
pos = parse_encoder(data, encA_ch, encB_ch); % [time enc_count]
fprintf('Encoder:\n  Logged %.1f rotations over %.1f seconds\n',...
    pos(end,2)/cpr, pos(end,1));

pos_by_trial = cell(num_trials, 1);
for k = 1:num_trials
    rows_k = (pos(:,1) >= screen_times(k,1)) & (pos(:,1) < screen_times(k,2));
    pos_k = pos(rows_k,:);
    pos_k(:,2) = pos_k(:,2) - pos_k(1,2); % Reset position for each trial
    pos_by_trial{k} = [pos_k; NaN NaN];
end
pos_cont = cell2mat(pos_by_trial);

% Rewards
us_times = find_edges(data, us_ch);

% Determine the number of pulses per reward. We assume pulses that occur in
% a rapid (sub-second) succession are part of a single reward
num_pulses_per_reward = sum((us_times - us_times(1)) < 0.1);
fprintf('Rewards:\n  Detected %d solenoid pulses per reward\n', num_pulses_per_reward);
us_times = us_times(1:num_pulses_per_reward:end);
num_rewards = length(us_times);

% Licks:
% Note: Can filter here for lick durations
lick_times = find_edges(data, lick_ch);

% Parse imaging clocks
%------------------------------------------------------------

ctx_frame_times = find_edges(data, ctx_clock_ch);
num_ctx_frames = length(ctx_frame_times);

str_frame_times = find_edges(data, str_clock_ch);
num_str_frames = length(str_frame_times);

%%

t = ctx_frame_times;
t_lims = t([1 end]);

yyaxis left;
plot(t, F(:,2) - 1, 'Color', [0 0.5 0]);
xlim(t_lims);
ylabel('Full-field GCaMP fluorescence (\DeltaF/F)');
xlabel('Time (s)');

ax = gca;
set(ax, 'TickLength', [0 0]);
ax.YAxis(1).Color = [0 0.5 0];
ax.YAxis(2).Color = 'k';

y_lims = [-500 500];

yyaxis right;
plot(pos_cont(:,1), pos_cont(:,2), 'k', 'LineWidth', 2);
hold on;
plot(t_lims, [0 0], 'k:');
plot_vertical_lines(us_times, y_lims, 'b-');
plot(lick_times, y_lims(1) + 0.95*diff(y_lims), 'b.');
hold off;
ylim(y_lims);

zoom xon;
ylabel('Encoder position during screen presentation');