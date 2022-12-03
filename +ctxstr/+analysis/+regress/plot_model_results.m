function [num_fitted_cells, num_cells] = plot_model_results(models, results, models_to_show, R2_lims)

num_models = length(models_to_show);
num_cells = length(results.fit_performed);
fitted_cell_inds = find(results.fit_performed)'; % Row vector
num_fitted_cells = length(fitted_cell_inds);

cla;
hold on;
for k = fitted_cell_inds
    he = errorbar(results.R2(k, models_to_show), results.error(k, models_to_show),...
        '.-', 'MarkerSize', 18);

    % The following lines were tested on Matlab 2022b
    he.DataTipTemplate.DataTipRows(1) = dataTipTextRow('Cell #', k*ones(1,num_models));
    he.DataTipTemplate.DataTipRows(2) = dataTipTextRow('Model #', models_to_show);
    he.DataTipTemplate.DataTipRows(3) = dataTipTextRow('R^2', 'YData', '%.4f');
end
hold off;
xlim([0 num_models+1]);
set(gca, 'XTick', 1:num_models);
set(gca, 'XTickLabel', cellfun(@(x) x.get_desc, models(models_to_show), 'UniformOutput', false));
set(gca, 'TickLabelInterpreter', 'none');
xtickangle(45);
ylabel('R^2_{Test}');
ylim(R2_lims);
ytickformat('%.2f');
set(gca, 'FontSize', 18);