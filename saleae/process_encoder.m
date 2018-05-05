function [pos, vel, info] = process_encoder(saleae_file, encA_ch, encB_ch, frame_clk_ch)

counter = count_enc_position(saleae_file, encA_ch, encB_ch);
frame_clk = find_edges(saleae_file, frame_clk_ch);

% Interpolate position at frame clock times
%------------------------------------------------------------
dt = 5; % Number of frames, used for velocity estimation

% A quirk of Matlab's 'interp1' is that if the query point Xq is out of
% range of the observed X, then interpolation returns NaN. Below, we pad
% X so that the range always contains Xq.
max_frame_time = max(frame_clk);
if (max_frame_time > counter(end,1))
    counter = [counter; max_frame_time+dt+1 counter(end,2)];
end

pos = interp1(counter(:,1), counter(:,2), frame_clk);
pos_next = interp1(counter(:,1), counter(:,2), frame_clk + dt);
pos_prev = interp1(counter(:,1), counter(:,2), frame_clk - dt);

vel = (pos_next - pos_prev)/(2*dt); % Clicks / frame

% Display results
ax1 = subplot(211);
plot(counter(:,1), counter(:,2), 'k.-');
grid on;
xlim(counter([1 end],1));
hold on;
plot(frame_clk, pos, 'r.');
hold off;
legend('True position', 'Sampled at frame clock', 'Location', 'NorthWest');
xlabel('Time (s)');
ylabel('Encoder position (clicks)');

ax2 = subplot(212);
plot(frame_clk, vel, 'r.-');
xlim(counter([1 end],1));
xlabel('Time (s)');
ylabel('Velocity (clicks/frame)');
grid on;

linkaxes([ax1 ax2], 'x');

% Additional info
info.dt = dt;