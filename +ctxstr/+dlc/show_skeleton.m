function show_skeleton(sdata, bdata)

t = sdata.t;
alpha_n = sdata.alpha_n; % Nose angle
beta_f = sdata.beta_f; % Front limb angle
beta_h = sdata.beta_h; % Hind limb angle
d_f = sdata.d_f; % Front limb position
d_h = sdata.d_h; % Hind limb position

% Behavior metadata
dataset_name = dirname;
x_lims = bdata.position.cont([1 end],1);

velocity = bdata.velocity;
position = cat(1, bdata.position.by_trial{:}); % Wrapped position

movement_onset_times = bdata.movement_onset_times(bdata.lick_responses);
us_times = bdata.us_times(bdata.lick_responses);
num_trials = length(us_times);
num_total_trials = length(bdata.lick_responses);

% Display results
%------------------------------------------------------------

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

% Encoder velocity and position
ax1 = sp(4,1,1);

yyaxis left;
v_lims = tight_plot(velocity(:,1), velocity(:,2));
ylabel('Velocity (cm/s)');
hold on;
% plot(x_lims, [0 0], 'k--');
y_pos = v_lims(1) + 0.95*diff(v_lims);
plot(bdata.lick_times,...
     y_pos*ones(size(bdata.lick_times)), 'b.');
hold off;

yyaxis right;
p_lims = tight_plot(position(:,1), position(:,2));
ylabel('Position (encoder count)');
hold on;
plot_rectangles(bdata.opto_periods, p_lims);
plot_vertical_lines(movement_onset_times, p_lims, 'r:');
plot_vertical_lines(us_times, p_lims, 'b:');
hold off;
xlim(x_lims);
title(sprintf('%s (%d consumed out of %d total trials)',...
        dataset_name, num_trials, num_total_trials));
set(ax1, 'TickLength', [0 0]);

% Nose angle
ax2 = sp(4,1,2);
y_lims = tight_plot(t, alpha_n);
hold on;
plot_rectangles(bdata.opto_periods, y_lims);
plot_vertical_lines(movement_onset_times, y_lims, 'r:');
plot_vertical_lines(us_times, y_lims, 'b:');
hold off;
ylabel('Body angle, \alpha_n (degrees)');
set(ax2, 'TickLength', [0 0]);

% Limb angles
ax3 = sp(4,1,3);
yyaxis left;
y_lims = [0 180];
tight_plot(t, beta_f);
hold on;
plot_rectangles(bdata.opto_periods, y_lims);
plot(t([1 end]), 90*[1 1], 'k--');
plot_vertical_lines(movement_onset_times, y_lims, 'r:');
plot_vertical_lines(us_times, y_lims, 'b:');
hold off;
ylim(y_lims);
set(ax3, 'YTick', [0 45 90 135 180]);
ylabel('Front limb angle, \beta_f (degrees)');

yyaxis right;
tight_plot(t, beta_h);
ylim(y_lims);
ylabel('Hind limb angle, \beta_h (degrees)');
set(ax3, 'TickLength', [0 0]);
set(ax3, 'YTick', [0 45 90 135 180]);

% Limb positions
ax4 = sp(4,1,4);
yyaxis left;
y_lims = tight_plot(t, d_f);
hold on;
plot_rectangles(bdata.opto_periods, y_lims);
plot_vertical_lines(movement_onset_times, y_lims, 'r:');
plot_vertical_lines(us_times, y_lims, 'b:');
hold off;
ylabel('Front limb position, d_f (px)');
xlabel('Time (s)');

yyaxis right;
tight_plot(t, d_h);
ylabel('Hind limb position, d_h (px)');

linkaxes([ax1 ax2 ax3 ax4], 'x');
zoom xon;

end

function plot_rectangles(x_ranges, y_lims)

for k = 1:size(x_ranges,1)
    x_range = x_ranges(k,:);
    w = x_range(2) - x_range(1);
    h = y_lims(2) - y_lims(1);
    rectangle('Position', [x_range(1) y_lims(1) w h],...
        'EdgeColor', 'none', 'FaceColor', [0 1 1 0.15]);
end

end