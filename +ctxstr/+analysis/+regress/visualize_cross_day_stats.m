function visualize_cross_day_stats(mouse_name, model_desc, days, ctx_R2s, ctx_cell_counts, str_R2s, str_cell_counts)

ax1 = subplot(3,2,[1 3]);
boxplot_wrapper(days, ctx_R2s);
grid on;
xlabel('Training day');
ylabel('Test R^2');
title({sprintf('%s-ctx', mouse_name),...
       sprintf('model=%s', model_desc)},...
      'Interpreter', 'none');

ax2 = subplot(3,2,[2 4]);
boxplot_wrapper(days, str_R2s);
grid on;
xlabel('Training day');
ylabel('Test R^2');
title({sprintf('%s-str', mouse_name),...
       sprintf('model=%s', model_desc)},...
      'Interpreter', 'none');

linkaxes([ax1 ax2], 'y');
ylim([0 1]);
set([ax1 ax2], 'FontSize', 14);

subplot(3,2,5);
bar(days, ctx_cell_counts(:,2), 'FaceColor', 0.95*[1 1 1]);
hold on;
bar(days, ctx_cell_counts(:,1), 'FaceColor', [0 0.447 0.741]);
hold off;
ylim([0 1.25*max(ctx_cell_counts(:,2))]);
grid on;
xlabel('Training day');
ylabel('Num cells');
set(gca, 'FontSize', 14);
legend('Total', 'Fitted', 'Location', 'NorthEast');
xlim([days(1)-0.5 days(end)+0.5]);

subplot(3,2,6);
bar(days, str_cell_counts(:,2), 0.75, 'FaceColor', 0.95*[1 1 1]);
hold on;
bar(days, str_cell_counts(:,1), 0.75, 'FaceColor', [0 0.447 0.741]);
hold off;
ylim([0 1.25*max(str_cell_counts(:,2))]);
grid on;
xlabel('Training day');
ylabel('Num cells');
set(gca, 'FontSize', 14);
legend('Total', 'Fitted', 'Location', 'NorthEast');
xlim([days(1)-0.5 days(end)+0.5]);