function skeleton = compute_skeleton(dlc_data, bdata)

front_left = dlc_data.front_left(:,1:2);
front_right = dlc_data.front_right(:,1:2);

hind_left = dlc_data.hind_left(:,1:2);
hind_right = dlc_data.hind_right(:,1:2);

nose = dlc_data.nose(:,1:2);
tail = dlc_data.tail(:,1:2);

% Behavior metadata
dataset_name = dirname;
x_lims = bdata.position.cont([1 end],1);

velocity = bdata.velocity;
position = cat(1, bdata.position.by_trial{:}); % Wrapped position

movement_onset_times = bdata.movement_onset_times(bdata.lick_responses);
us_times = bdata.us_times(bdata.lick_responses);
num_trials = length(us_times);
num_total_trials = length(bdata.lick_responses);

% Compute skeleton parameters. See definitions from 2020 Oct 20 diagram
%------------------------------------------------------------

% Angles
body_vec = tail - nose; % Nose-to-tail vector
alpha_n = 180/pi*atan2(body_vec(:,2), body_vec(:,1));

front_limb_vec = front_right - front_left;
alpha_f = 180/pi*atan2(front_limb_vec(:,2), front_limb_vec(:,1));

hind_limb_vec = hind_right - hind_left;
alpha_h = 180/pi*atan2(hind_limb_vec(:,2), hind_limb_vec(:,1));

beta_f = alpha_f - alpha_n;
beta_h = alpha_h - alpha_n;

% Distances
body_dir = normr(body_vec);

front_vec = 1/2*(front_left + front_right) - nose;
hind_vec = 1/2*(hind_left + hind_right) - nose;

d_f = sum(front_vec .* body_dir,2);
d_h = sum(hind_vec .* body_dir,2);

skeleton.alpha_n = alpha_n;
skeleton.alpha_f = alpha_f;
skeleton.alpha_h = alpha_h;
skeleton.beta_f = beta_f;
skeleton.beta_h = beta_h;
skeleton.d_f = d_f;
skeleton.d_h = d_h;

% Display results
%------------------------------------------------------------

ax1 = subplot(411);

yyaxis left;
v_lims = tight_plot(velocity(:,1), velocity(:,2));
ylabel('Velocity (cm/s)');
hold on;
plot(x_lims, [0 0], 'k--');
y_pos = v_lims(1) + 0.95*diff(v_lims);
plot(bdata.lick_times,...
     y_pos*ones(size(bdata.lick_times)), 'b.');
hold off;

yyaxis right;
p_lims = tight_plot(position(:,1), position(:,2));
ylabel('Position (encoder count)');
hold on;
plot_vertical_lines(movement_onset_times, p_lims, 'r:');
plot_vertical_lines(us_times, p_lims, 'b:');
hold off;
xlim(x_lims);
title(sprintf('%s (%d consumed out of %d total trials)',...
        dataset_name, num_trials, num_total_trials));
set(ax1, 'TickLength', [0 0]);

ax2 = subplot(412);
y_lims = tight_plot(dlc_data.t, alpha_n);
hold on;
plot_vertical_lines(movement_onset_times, y_lims, 'r:');
plot_vertical_lines(us_times, y_lims, 'b:');
hold off;
ylabel('Body angle, \alpha_n (degrees)');
set(ax2, 'TickLength', [0 0]);

ax3 = subplot(413);
yyaxis left;
y_lims = [0 180];
tight_plot(dlc_data.t, beta_f);
hold on;
plot(dlc_data.t([1 end]), 90*[1 1], 'k--');
plot_vertical_lines(movement_onset_times, y_lims, 'r:');
plot_vertical_lines(us_times, y_lims, 'b:');
hold off;
ylim(y_lims);
set(ax3, 'YTick', [0 45 90 135 180]);
ylabel('Front limb angle, \beta_f (degrees)');

yyaxis right;
tight_plot(dlc_data.t, beta_h);
ylim(y_lims);
ylabel('Hind limb angle, \beta_h (degrees)');
set(ax3, 'TickLength', [0 0]);
set(ax3, 'YTick', [0 45 90 135 180]);

ax4 = subplot(414);
yyaxis left;
y_lims = tight_plot(dlc_data.t, d_f);
hold on;
plot_vertical_lines(movement_onset_times, y_lims, 'r:');
plot_vertical_lines(us_times, y_lims, 'b:');
hold off;
ylabel('Front limb position, d_f (px)');
xlabel('Time (s)');

yyaxis right;
tight_plot(dlc_data.t, d_h);
ylabel('Hind limb position, d_h (px)');

linkaxes([ax1 ax2 ax3 ax4], 'x');
zoom xon;

end % compute_skeleton
