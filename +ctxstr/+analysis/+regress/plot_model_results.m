function [num_fitted_cells, num_cells] = plot_model_results(models, results, active_frac_thresh, R2_lims)

num_models = length(models);
num_cells = length(results.active_fracs);
num_fitted_cells = 0;

cla;
hold on;
for k = 1:num_cells
    active_frac_k = results.active_fracs(k);
    if active_frac_k > active_frac_thresh
        errorbar(results.R2(k,:), results.error(k,:),...
            '.-', 'MarkerSize', 18);
        num_fitted_cells = num_fitted_cells + 1;
    end
end
hold off;
xlim([0 num_models+1]);
set(gca, 'XTick', 1:num_models);
set(gca, 'XTickLabel', cellfun(@(x) x.get_desc, models, 'UniformOutput', false));
set(gca, 'TickLabelInterpreter', 'none');
xtickangle(45);
ylabel('Test R^2');
ylim(R2_lims);
ytickformat('%.2f');
set(gca, 'FontSize', 18);