clear all; close all;

load('regression.mat');
cprintf('blue', 'Loaded regression results for "%s"\n', dataset_name);

% Dock all figures for convenience
set(0, 'DefaultFigureWindowStyle', 'docked');

%% Show R2 for all cells and (selected) models

models_to_show = [1:6 8 10];
R2_lims = [0 0.6]; % y-range for plots

figure(1);
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

brain_area = 's'; % 'ctx'/'c' or 'str'/'s'
cell_idx = 105;
model_no = 10;
split_no = 1;

switch brain_area
    case {'ctx', 'c'}
        brain_area = 'ctx';
        trace_by_trial = ctxstr.core.get_traces_for_cell(binned_ctx_traces_by_trial, cell_idx);
        fd = ctx_fit.data{cell_idx, model_no, split_no};

    case {'str', 's'}
        brain_area = 'str';
        trace_by_trial = ctxstr.core.get_traces_for_cell(binned_str_traces_by_trial, cell_idx);
        fd = str_fit.data{cell_idx, model_no, split_no};
end

if isempty(fd)
    error('Fit data is empty. Is the requested brain area correct?');
else
    fprintf('Visualizing %s-%s, Cell=%d...\n', dataset_name, brain_area, cell_idx);
    % Show the detailed fit
    figure(2);
    ctxstr.analysis.regress.visualize_fit(...
                    time_by_trial, trace_by_trial, fd.train_trial_inds, fd.test_trial_inds,...
                    models{model_no}, fd.kernels, fd.biases, fd.train_results, fd.test_results,...
                    t, reward_frames, motion_frames, velocity, accel, lick_rate);
    title(sprintf('%s-%s, Cell=%d, model #=%d, split #=%d',...
                dataset_name, brain_area, cell_idx, model_no, split_no));

    % Show the cell raster
    figure(3);
    load('resampled_data.mat', 'st_trial_inds', 'trials');
    ctxstr.vis.show_aligned_binned_raster(st_trial_inds, trials,...
        ctxstr.core.concatenate_trials(trace_by_trial), t);
    title(sprintf('%s-%s, Cell %d', dataset_name, brain_area, cell_idx));
end

