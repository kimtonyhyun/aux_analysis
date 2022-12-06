function visualize_cross_day_stats(mouse_name, model_desc, days, ctx_R2s, ctx_cell_counts, str_R2s, str_cell_counts)

get_R2_vals = @(array) cellfun(@(x) x(:,1), array, 'UniformOutput', false);

ctx_R2_vals = get_R2_vals(ctx_R2s);
str_R2_vals = get_R2_vals(str_R2s);

% Compute the max observed R2s over all cortical and striatal cells, over all days
max_ctx_R2 = max(cell2mat(ctx_R2_vals));
max_str_R2 = max(cell2mat(str_R2_vals));
max_R2 = max([max_ctx_R2 max_str_R2]);

ax1 = subplot(3,2,[1 3]);
boxplot_wrapper(days, ctx_R2_vals);
plot_top_k_cells(days, ctx_R2s);
grid on;
ylabel('Single-cell R^2_{test} values');
title({sprintf('%s-ctx', mouse_name),...
       sprintf('model=%s', model_desc)},...
      'Interpreter', 'none');

ax2 = subplot(3,2,[2 4]);
boxplot_wrapper(days, str_R2_vals);
plot_top_k_cells(days, str_R2s);
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

datacursormode on;

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

function plot_top_k_cells(days, R2s)

num_to_plot = 10;

top_cells = cellfun(@ctxstr.analysis.regress.get_top_fits, R2s, 'UniformOutput', false);
hold on;
for k = 1:length(days)
    N = min([num_to_plot size(top_cells{k},1)]);
    ht = plot(days(k)*ones(N,1), top_cells{k}(1:N,1), 'o',...
            "MarkerSize", 6, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k');
    ht.DataTipTemplate.DataTipRows(1) = dataTipTextRow('Cell #', top_cells{k}(1:N,2));
    ht.DataTipTemplate.DataTipRows(2) = dataTipTextRow('R^2 #', 'YData', '%.4f');
end
hold off;

end