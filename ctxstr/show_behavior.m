function show_behavior(behavior)

% Note: Assumes directory name is the dataset name
dataset_name = dirname;
x_lims = behavior.position.cont([1 end],1);

velocity = behavior.velocity;
v_lims = compute_range(velocity(:,2));

position = cat(1, behavior.position.by_trial{:}); % Wrapped position
p_lims = compute_range(position(:,2));

movement_onset_times = behavior.movement_onset_times;
us_times = behavior.us_times;
runtimes = us_times - movement_onset_times;
avg_runtime = mean(runtimes);
num_trials = length(us_times);

% Show velocity and position over the session
%------------------------------------------------------------
ax1 = subplot(311);

yyaxis left;
plot(velocity(:,1), velocity(:,2));
ylabel('Velocity (cm/s)');
hold on;
plot(x_lims, [0 0], 'k--');
hold off;
ylim(v_lims);

yyaxis right;
plot(position(:,1), position(:,2));
ylabel('Position (encoder count)');
hold on;
my_xline(movement_onset_times, p_lims, 'r:');
my_xline(us_times, p_lims, 'b:');
hold off;
xlim(x_lims);
ylim(p_lims);
zoom xon;
xlabel('Time (s)');
title(sprintf('%s (%d trials)', dataset_name, num_trials));
set(ax1, 'TickLength', [0 0]);


% Align to movement onset
%------------------------------------------------------------
t = -2:0.1:(avg_runtime+2);
V_movement_onset = get_aligned_raster(velocity, movement_onset_times, t);
P_movement_onset = get_aligned_raster(position, movement_onset_times, t);

ax2 = subplot(3,2,3);
plotShadedErrorBar(t, V_movement_onset, [0 0.447 0.741]);
hold on;
plot(t([1 end]), [0 0], 'k--');
my_xline(0, v_lims, 'r');
my_xline(runtimes, v_lims, 'b:');
hold off;
ylabel('Velocity (cm/s)');
ylim(v_lims);
% grid on;
title('Align to movement onset');

ax3 = subplot(3,2,5);
plotShadedErrorBar(t, P_movement_onset, [0.85 0.325 0.098]);
hold on;
plot(t([1 end]), [0 0], 'k--');
my_xline(0, p_lims, 'r');
my_xline(runtimes, p_lims, 'b:');
hold off;
ylabel('Position (encoder count)');
ylim(p_lims);
% grid on;
xlabel('Time relative to movement onset (s)');

linkaxes([ax2 ax3], 'x');
xlim(t([1 end]));

% Align to US
%------------------------------------------------------------
t = -(avg_runtime+2):0.1:2;

% Omission of the last US is a hack. This is necessary because "position"
% terminates with the very last US.
V_us = get_aligned_raster(velocity, us_times(1:end-1), t);
P_us = get_aligned_raster(position, us_times(1:end-1), t);

ax4 = subplot(3,2,4);
plotShadedErrorBar(t, V_us, [0 0.447 0.741]);
hold on;
plot(t([1 end]), [0 0], 'k--');
my_xline(0, v_lims, 'b');
my_xline(-runtimes, v_lims, 'r:');
hold off;
ylabel('Velocity (cm/s)');
ylim(v_lims);
% grid on;
title('Align to US');

ax5 = subplot(3,2,6);
plotShadedErrorBar(t, P_us, [0.85 0.325 0.098]);
hold on;
plot(t([1 end]), [0 0], 'k--');
my_xline(0, p_lims, 'b');
my_xline(-runtimes, p_lims, 'r:');
hold off;
ylabel('Position (encoder count)');
ylim(p_lims);
% grid on;
xlabel('Time relative to US (s)');

linkaxes([ax4 ax5], 'x');
xlim(t([1 end]));

end

function range = compute_range(trace)
    range = [min(trace) max(trace)];
    range = range + 0.1*diff(range)*[-1 1];
end

function R = get_aligned_raster(data, alignment_times, sample_window)
    num_trials = length(alignment_times);
    num_samples = length(sample_window);
    R = zeros(num_trials, num_samples);
    for k = 1:num_trials
        R(k,:) = interp1(data(:,1), data(:,2), alignment_times(k) + sample_window);
    end
end

function plotShadedErrorBar(x, Y, color)
    N = size(Y,1);
    shadedErrorBar(x, mean(Y), std(Y)/sqrt(N), 'lineprops', {'Color', color});
end

function my_xline(xs, y_range, linespec)
    % Built-in 'xline' seems to be extremely slow to render
    xs = xs(:)'; % Force row vector
    y_range = y_range(:)';
    
    num_x = length(xs);
    X = kron(xs, [1 1 NaN]);
    Y = repmat([y_range NaN], 1, num_x);
    
    plot(X,Y,linespec);
end