function visualize_cross_day_stats(mouse_name, model_desc, days, ctx_R2s, ctx_cell_counts, str_R2s, str_cell_counts)

max_R2 = max([cell2mat(ctx_R2s)' cell2mat(str_R2s)']);

ax1 = subplot(3,2,[1 3]);
boxplot_wrapper(days, ctx_R2s);
grid on;
ylabel('Single-cell R^2_{test} values');
title({sprintf('%s-ctx', mouse_name),...
       sprintf('model=%s', model_desc)},...
      'Interpreter', 'none');

ax2 = subplot(3,2,[2 4]);
boxplot_wrapper(days, str_R2s);
grid on;
title({sprintf('%s-str', mouse_name),...
       sprintf('model=%s', model_desc)},...
      'Interpreter', 'none');

linkaxes([ax1 ax2], 'y');
ylim([0 max_R2+0.05]);
set([ax1 ax2], 'FontSize', 14);

ax3 = subplot(3,2,5);
plot_cell_counts(days, ctx_cell_counts(:,2), ctx_cell_counts(:,1));
ylabel('Num cells');
title('Ctx cell counts');

ax4 = subplot(3,2,6);
plot_cell_counts(days, str_cell_counts(:,2), str_cell_counts(:,1));
title('Str cell counts');

all_axes = [ax1 ax2 ax3 ax4];
xlim(all_axes, [days(1)-0.5 days(end)+0.5]);
set(all_axes, 'TickLength', [0 0]);

end

function plot_cell_counts(days, total, fitted)

bar_width = 0.65;
bar(days, total, bar_width, 'FaceColor', 0.95*[1 1 1]); % Light gray
hold on;
bar(days, fitted, bar_width, 'FaceColor', [0 0.447 0.741]); % Light blue
hold off;
for k = 1:length(days)
    text(days(k), total(k), num2str(total(k)),...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'bottom');
    text(days(k), fitted(k)/2, num2str(fitted(k)),...
        'Color', 'w', 'HorizontalAlignment', 'center');
end
grid on;
xlabel('Training day');
set(gca, 'FontSize', 14);
% legend('Total', 'Fitted', 'Location', 'NorthEast');
xlim([days(1)-0.5 days(end)+0.5]);
ylim([0 max(total)+25]);

end