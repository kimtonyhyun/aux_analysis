function draw_traces(trials_to_use, trials, time, traces1, traces2, color1, color2)

t_lims = [trials(trials_to_use(1)).start_time trials(trials_to_use(end)).us_time];
y_lims = [-0.15 1.15];

hold on;
for k = trials_to_use
    trial = trials(k);
    
    plot(time{k}, traces1{k}, 'Color', color1);
    plot(time{k}, traces2{k}, 'Color', color2);
    plot_vertical_lines([trial.start_time, trial.us_time], y_lims, 'b:');
    plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
end
hold off;
xlim(t_lims);
ylim(y_lims);

set(gca, 'TickLength', [0.001 0]);
set(gca, 'XTick', [trials(trials_to_use).start_time]);
set(gca, 'XTickLabel', trials_to_use);
set(gca, 'YTick', [0 1]);

zoom xon;