function plot_screen_update_latency(s)

figure;
hold on;
colors = 'kbr';
num_colors = length(colors);

for k = 1:s.num_trials
    color = colors(mod(k, num_colors) + 1);

    latency = s.screen_update_latency{k} * 1e3; % ms
    plot(s.screen_update_times{k}, latency, '.-', 'Color', color);
end

t_lims = [s.screen_update_times{1}(1) s.screen_update_times{end}(end)];

all_latency = cell2mat(s.screen_update_latency) * 1e3;
mean_latency = mean(all_latency);
std_latency = std(all_latency);
plot(t_lims, mean_latency * [1 1], 'k--');

hold off;
xlabel('Time (s)');
ylabel('Screen update latency (ms)');
title({sprintf('Mean latency = %.3f \\pm %.3f ms', mean_latency, std_latency),...
       sprintf('%d screen updates', length(all_latency))});
xlim(t_lims);
grid on;
set(gca, 'FontSize', 18);

zoom xon;