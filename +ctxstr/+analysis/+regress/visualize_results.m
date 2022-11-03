clear all;

load('regression.mat');
cprintf('blue', 'Loaded regression results for "%s"\n', dataset_name);

%% Show R2 for all cells and (selected) models

models_to_show = [1:6 8 10];
R2_lims = [0 0.5]; % y-range for plots

subplot(121);
[num_fitted_ctx_cells, num_ctx_cells] = ctxstr.analysis.regress.plot_model_results(...
    models, ctx_fit.results, models_to_show, R2_lims);
title(sprintf('%s-ctx, Showing %d fits out of %d cells total',...
    dataset_name, num_fitted_ctx_cells, num_ctx_cells));

subplot(122);
[num_fitted_str_cells, num_str_cells] = ctxstr.analysis.regress.plot_model_results(...
    models, str_fit.results, models_to_show, R2_lims);
title(sprintf('%s-str, Showing %d fits out of %d cells total',...
    dataset_name, num_fitted_str_cells, num_str_cells));

datacursormode on; % Allows clicking of data points to retrieve cell idx and other info

%% Visualize a specific fit (defined by cell_idx × model_no × split_no)

brain_area = 'ctx'; % 'ctx' or 'str'
cell_idx = 47;
model_no = 6;
split_no = 1;

switch brain_area
    case 'ctx'
        trace_by_trial = ctxstr.core.get_traces_for_cell(binned_ctx_traces_by_trial, cell_idx);
        fd = ctx_fit.data{cell_idx, model_no, split_no};

    case 'str'
        trace_by_trial = ctxstr.core.get_traces_for_cell(binned_str_traces_by_trial, cell_idx);
        fd = str_fit.data{cell_idx, model_no, split_no};
end

figure;
ctxstr.analysis.regress.visualize_fit(...
                time_by_trial, trace_by_trial, fd.train_trial_inds, fd.test_trial_inds,...
                models{model_no}, fd.kernels, fd.biases, fd.train_results, fd.test_results,...
                t, reward_frames, motion_frames, velocity, accel, lick_rate);
title(sprintf('%s-%s, Cell=%d, model #=%d, split #=%d',...
            dataset_name, brain_area, cell_idx, model_no, split_no));

%% Show cell raster

load('resampled_data.mat', 'st_trial_inds', 'trials');

figure;
ctxstr.vis.show_aligned_binned_raster(st_trial_inds, trials,...
    ctxstr.core.concatenate_trials(trace_by_trial), t);
title(sprintf('%s-%s, Cell %d', dataset_name, brain_area, cell_idx));