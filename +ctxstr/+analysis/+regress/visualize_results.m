clear all;

load('regression.mat');

%%

R2_lims = [0 0.5]; % y-range for plots

subplot(121);
[num_fitted_ctx_cells, num_ctx_cells] = ctxstr.analysis.regress.plot_model_results(...
    models, ctx_fit.results, active_frac_thresh, R2_lims);
title(sprintf('%s-ctx, Showing %d fits out of %d cells total',...
    dataset_name, num_fitted_ctx_cells, num_ctx_cells));

subplot(122);
[num_fitted_str_cells, num_str_cells] = ctxstr.analysis.regress.plot_model_results(...
    models, str_fit.results, active_frac_thresh, R2_lims);
title(sprintf('%s-str, Showing %d fits out of %d cells total',...
    dataset_name, num_fitted_str_cells, num_str_cells));

%%

cell_idx = 47;
model_no = 6;
split_no = 1;

binned_traces_by_trial = ctxstr.core.get_traces_for_cell(binned_ctx_traces_by_trial, cell_idx);
fd = ctx_fit.data{cell_idx, model_no, split_no};

figure;
ctxstr.analysis.regress.visualize_fit(...
                time_by_trial, binned_traces_by_trial, fd.train_trial_inds, fd.test_trial_inds,...
                models{model_no}, fd.kernels, fd.biases, fd.train_results, fd.test_results,...
                t, reward_frames, motion_frames, velocity, accel, lick_rate);