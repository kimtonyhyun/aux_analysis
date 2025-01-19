function plot_RT_delays(s)
% Use with the output of 'bmi.validate_rt_processing'

t_lims = [1 s.num_frames];
frame_period = s.frame_clk.period;

stem(s.RT_delay_by_frame * 1e3, '.', 'MarkerSize', 12);
% grid on;
hold on;
plot(t_lims, frame_period*[1 1] * 1e3, ':', 'LineWidth', 2, 'Color', [0.4660 0.6740 0.1880]); % Green
plot(t_lims, 2*frame_period*[1 1] * 1e3, ':', 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]); % Orange
plot(t_lims, 3*frame_period*[1 1] * 1e3, ':', 'LineWidth', 2, 'Color', [0.6350 0.0780 0.1840]); % Red
hold off;
xlabel('Frame index');
ylabel('BMI output delay (ms)');
set(gca, 'TickLength', [0 0]);
xlim(t_lims);
zoom xon;