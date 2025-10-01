function show_skeleton(path_to_behavior, path_to_skeleton)

show_trial_idx = true;

% Defaults
%------------------------------------------------------------
if ~exist('path_to_behavior', 'var')
    path_to_behavior = 'ctxstr.mat';
end
bdata = load(path_to_behavior);
behavior = bdata.behavior;
fprintf('Loaded behavioral data from "%s"\n', path_to_behavior);

if ~exist('path_to_skeleton', 'var')
    path_to_skeleton = 'skeleton.mat';
end
sdata = load(path_to_skeleton);
fprintf('Loaded skeleton (DLC) data from "%s"\n', path_to_skeleton);

t = sdata.t;
alpha_n = sdata.alpha_n; % Nose angle
beta_f = sdata.beta_f; % Front limb angle
beta_h = sdata.beta_h; % Hind limb angle
d_f = sdata.d_f; % Front limb position
d_h = sdata.d_h; % Hind limb position

% Behavior metadata
dataset_name = dirname;
x_lims = behavior.position.cont([1 end],1);

velocity = behavior.velocity;
position = cat(1, behavior.position.by_trial{:}); % Wrapped position

movement_onset_times = behavior.movement_onset_times;
us_times = behavior.us_times;
num_trials = length(us_times);

% Display results
%------------------------------------------------------------

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

% Encoder velocity and position
ax1 = sp(4,1,1);

yyaxis left;
v_lims = tight_plot(velocity(:,1), velocity(:,2), 'HitTest', 'off');
ylabel('Velocity (cm/s)');
hold on;
% plot(x_lims, [0 0], 'k--');
y_pos = v_lims(1) + 0.95*diff(v_lims);
plot(behavior.lick_times, y_pos*ones(size(behavior.lick_times)),...
    'b.', 'HitTest', 'off');
hold off;

yyaxis right;
p_lims = tight_plot(position(:,1), position(:,2), 'HitTest', 'off');
ylabel('Position (encoder count)');
hold on;
% plot_rectangles(behavior.opto_periods, p_lims);
% plot_vertical_lines(movement_onset_times, p_lims, 'r:', 'HitTest', 'off');
plot_vertical_lines(us_times, p_lims, 'b:', 'HitTest', 'off');
hold off;
xlim(x_lims);
title(sprintf('%s (%d consumed out of %d total trials)',...
        dataset_name, sum(behavior.lick_responses), num_trials));
set(ax1, 'TickLength', [0 0]);

% Nose angle
ax2 = sp(4,1,2);
y_lims = tight_plot(t, alpha_n, 'HitTest', 'off');
hold on;
% plot_rectangles(behavior.opto_periods, y_lims);
% plot_vertical_lines(movement_onset_times, y_lims, 'r:', 'HitTest', 'off');
plot_vertical_lines(us_times, y_lims, 'b:', 'HitTest', 'off');
hold off;
ylabel('Body angle, \alpha_n (degrees)');
set(ax2, 'TickLength', [0 0]);

% Limb angles
ax3 = sp(4,1,3);
yyaxis left;
y_lims = [0 180];
tight_plot(t, beta_f, 'HitTest', 'off');
hold on;
% plot_rectangles(behavior.opto_periods, y_lims);
plot(t([1 end]), 90*[1 1], 'k--');
% plot_vertical_lines(movement_onset_times, y_lims, 'r:', 'HitTest', 'off');
plot_vertical_lines(us_times, y_lims, 'b:', 'HitTest', 'off');
hold off;
ylim(y_lims);
set(ax3, 'YTick', [0 45 90 135 180]);
ylabel('Front limb angle, \beta_f (degrees)');

yyaxis right;
tight_plot(t, beta_h, 'HitTest', 'off');
ylim(y_lims);
ylabel('Hind limb angle, \beta_h (degrees)');
set(ax3, 'TickLength', [0 0]);
set(ax3, 'YTick', [0 45 90 135 180]);

% Limb positions
ax4 = sp(4,1,4);
yyaxis left;
y_lims = tight_plot(t, d_f, 'HitTest', 'off');
hold on;
% plot_rectangles(behavior.opto_periods, y_lims);
% plot_vertical_lines(movement_onset_times, y_lims, 'r:', 'HitTest', 'off');
plot_vertical_lines(us_times, y_lims, 'b:', 'HitTest', 'off');
hold off;
ylabel('Front limb position, d_f (px)');
xlabel('Time (s)');
yyaxis right;
tight_plot(t, d_h, 'HitTest', 'off');
ylabel('Hind limb position, d_h (px)');
set(ax4, 'TickLength', [0 0]);

linkaxes([ax1 ax2 ax3 ax4], 'x');
zoom xon;

if show_trial_idx
    for a = [ax1 ax2 ax3 ax4]
        set(a, 'XTick', behavior.us_times(1:5:end));
        set(a, 'XTickLabel', 1:5:num_trials);
    end
    xlabel('Reward index');
end

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