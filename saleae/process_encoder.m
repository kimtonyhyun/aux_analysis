function [pos_t, vel_t, info] = process_encoder(saleae_file, encA_ch, encB_ch, frame_clk_ch, varargin)

dt = 0.05; % seconds, used for velocity estimation
trial_indices = [];

for i = 1:length(varargin)
    vararg = varargin{i};
    if ischar(vararg)
        switch lower(vararg)
            % If trial indices are provided, then we will "zero" the
            % position at the beginning of each trial
            case {'trial', 'trials'}
                trial_indices = varargin{i+1};
        end
    end
end

counter = count_enc_position(saleae_file, encA_ch, encB_ch);
frame_clk = find_edges(saleae_file, frame_clk_ch);

if isempty(trial_indices)
    trial_indices = [1 length(frame_clk)];
end

% Interpolate position at frame clock times
%------------------------------------------------------------

% A quirk of Matlab's 'interp1' is that if the query point Xq is out of
% range of the observed X, then interpolation returns NaN. Below, we pad
% X so that the range always contains Xq.
max_frame_time = max(frame_clk);
if (max_frame_time > counter(end,1))
    counter = [counter; max_frame_time+dt+1 counter(end,2)];
end

pos = interp1(counter(:,1), counter(:,2), frame_clk);

% Sample the velocity
pos_next = interp1(counter(:,1), counter(:,2), frame_clk + dt);
pos_prev = interp1(counter(:,1), counter(:,2), frame_clk - dt);
vel = (pos_next - pos_prev)/(2*dt); % Clicks / s

% Parse position and velocity data into trial chunks.
%------------------------------------------------------------
num_trials = size(trial_indices,1);

frames_t = cell(num_trials,1);
pos_t = cell(num_trials,1);
vel_t = cell(num_trials,1);

for k = 1:num_trials
    trial_frames = trial_indices(k,1):trial_indices(k,end);
    frames_t{k} = frame_clk(trial_frames);
    pos_t{k} = pos(trial_frames) - pos(trial_frames(1));
    vel_t{k} = vel(trial_frames);
end

% Display results
ax1 = subplot(211);
for k = 1:num_trials
    plot(frames_t{k}, pos_t{k}, 'r.-');
    hold on;
end
hold off;
grid on;
xlim(counter([1 end],1));
xlabel('Time (s)');
ylabel('Encoder position (clicks)');

ax2 = subplot(212);
for k = 1:num_trials
    plot(frames_t{k}, vel_t{k}, 'r.-');
    hold on;
end
hold off;
xlim(counter([1 end],1));
xlabel('Time (s)');
ylabel('Velocity (clicks / s)');
title(sprintf('Linear slope fit over \\pm%.3f seconds', dt));
grid on;

linkaxes([ax1 ax2], 'x');

% Additional info
info.dt = dt;
info.frames = frames_t;