%% Perform multiple linear regression

figure;

str_idx_to_fit = 22;
y = cont_str_traces(str_idx_to_fit,:)'; % [Time x 1]

type = 'from_ctx';
switch (type)
    case 'from_ctx'
        X = cont_ctx_traces'; % Design matrix, [Time x Ctx-neurons]
        [~, sort_inds] = sort(C_ctxstr(:,str_idx_to_fit), 'descend');
        get_predictors = @(k) resampled_ctx_traces{k};
        get_cell_ind = @(j) j;
        get_corr_val = @(j) C_ctxstr(get_cell_ind(j), str_idx_to_fit);
        cell_type = 'Ctx';
        
    case 'from_str'
        remaining_str_inds = setdiff(1:num_str_cells, str_idx_to_fit);
        X = cont_str_traces(remaining_str_inds,:)';
        [~, sort_inds] = sort(C_str(remaining_str_inds, str_idx_to_fit), 'descend');
        get_predictors = @(k) resampled_str_traces{k}(remaining_str_inds,:);
        get_cell_ind = @(j) remaining_str_inds(j);
        get_corr_val = @(j) C_str(get_cell_ind(j), str_idx_to_fit);
        cell_type = 'Str';
end

lambda = 0;
theta = (X'*X+lambda*eye(size(X,2)))\X'*y;

% Show results
%------------------------------------------------------------
individual_cells_to_show = [sort_inds(1:5)]';

y_lims = [-0.15 1.15];
sp = @(m,n,p) subtightplot(m, n, p, [0.01 0.05], 0.04, 0.04); % Gap, Margin-X, Margin-Y

num_cells_to_show = length(individual_cells_to_show);
num_rows = 1 + num_cells_to_show;
h_axes = zeros(num_rows, 1);

str_trace_fit = cell(1, num_all_trials);
h_axes(1) = sp(num_rows,1,1);
hold on;
for k = trials_to_use
    trial = trials(k);

    str_trace_fit{k} = theta' * get_predictors(k);
    
    plot(common_time{k}, resampled_str_traces{k}(str_idx_to_fit,:), 'm');
    plot(common_time{k}, str_trace_fit{k}, 'k');
    plot_vertical_lines([trial.start_time, trial.us_time], y_lims, 'b:');
    plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
end
hold off;
cont_str_trace_fit = cell2mat(str_trace_fit);
R2_val = 1 - var(y' - cont_str_trace_fit)/var(y);
ylabel({sprintf('All %s neurons', cell_type), sprintf('R^2 = %.4f', R2_val)}, ...
       'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
title(sprintf('Multiple linear regression result for Str cell=%d', str_idx_to_fit));

for r = 2:num_rows
    h_axes(r) = sp(num_rows,1,r);
    hold on;
    for k = trials_to_use
        trial = trials(k);

        j = individual_cells_to_show(r-1);
        theta_j = theta(j);
        pred_traces = get_predictors(k);
        str_trace_fit{k} = theta_j * pred_traces(j,:);

        plot(common_time{k}, resampled_str_traces{k}(str_idx_to_fit,:), 'm');
        plot(common_time{k}, str_trace_fit{k}, 'Color', 0.3*[1 1 1]);
        plot_vertical_lines([trial.start_time, trial.us_time], y_lims, 'b:');
        plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
    end
    hold off;
    cont_str_trace_fit = cell2mat(str_trace_fit);
    R2_val = 1 - var(y' - cont_str_trace_fit)/var(y);
    ylabel({sprintf('%s cell=%d', cell_type, get_cell_ind(j)),...
            sprintf('\\rho = %.4f', get_corr_val(j)),...
            sprintf('\\theta_{%d} = %.4f', get_cell_ind(j), theta_j),...
            sprintf('R^2 = %.4f', R2_val)},...
            'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
end

set(h_axes, 'TickLength', [0.001 0]);
set(h_axes, 'YTick', [0 1]);
set(h_axes(1:end-1), 'XTick', []);
set(h_axes(end), 'XTick', trial_start_times);
set(h_axes(end), 'XTickLabel', trials_to_use);

linkaxes(h_axes, 'xy');
ylim(y_lims);
xlim(t_lims);

zoom xon;