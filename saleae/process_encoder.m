function [pos, vel] = process_encoder(saleae_file, encA_ch, encB_ch, frame_clk_ch)

counter = count_enc_position(saleae_file, encA_ch, encB_ch);
frame_clk = find_edges(saleae_file, frame_clk_ch);

% Interpolate position at frame clock times
pos = interp1(counter(:,1), counter(:,2), frame_clk);

dt = 1;
pos_next = interp1(counter(:,1), counter(:,2), frame_clk + dt);
pos_prev = interp1(counter(:,1), counter(:,2), frame_clk - dt);

vel = (pos_next - pos_prev)/(2*dt);

% Display results
subplot(211);
plot(counter(:,1), counter(:,2), 'k.-');
grid on;
xlim(counter([1 end],1));
hold on;
plot(frame_clk, pos, 'r.');
hold off;
legend('True position', 'Sampled at frame clock', 'Location', 'NorthWest');
xlabel('Time (s)');
ylabel('Encoder position (clicks)');

subplot(212);
plot(frame_clk, vel, 'r.-');
xlim(counter([1 end],1));
xlabel('Time (s)');
ylabel('Velocity (clicks/frame)');
grid on;