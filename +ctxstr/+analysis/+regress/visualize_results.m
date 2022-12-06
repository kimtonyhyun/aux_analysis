clear all; %close all;

reg = load('regression.mat');
cprintf('blue', 'Loaded regression results for "%s"\n', reg.dataset_name);

% Dock all figures for convenience
set(0, 'DefaultFigureWindowStyle', 'docked');

%% Show R2 for all cells across (selected) models

models_to_show = [1:6 8 10];
R2_lims = [0 0.8]; % y-range for plots

figure(1);
subplot(121);
if ~isempty(reg.ctx_fit)
    [num_fitted_ctx_cells, num_ctx_cells] = ctxstr.analysis.regress.plot_model_results(...
        reg.models, reg.ctx_fit.results, models_to_show, R2_lims);
    title(sprintf('%s-ctx, Showing %d fits out of %d cells total',...
        reg.dataset_name, num_fitted_ctx_cells, num_ctx_cells));
end

subplot(122);
if ~isempty(reg.str_fit)
    [num_fitted_str_cells, num_str_cells] = ctxstr.analysis.regress.plot_model_results(...
        reg.models, reg.str_fit.results, models_to_show, R2_lims);
    title(sprintf('%s-str, Showing %d fits out of %d cells total',...
        reg.dataset_name, num_fitted_str_cells, num_str_cells));
end

datacursormode on; % Allows clicking of data points to retrieve cell idx and other info

%% Get list of top fits for ctx & str, for the chosen regression model

model_no = 8;

ctx_top_fits = ctxstr.analysis.regress.get_top_fits(reg.ctx_fit.results.R2(:,model_no));
str_top_fits = ctxstr.analysis.regress.get_top_fits(reg.str_fit.results.R2(:,model_no));

%% Visualize a specific fit (defined by cell_idx × model_no × split_no)
% TODO: Simplify and unify code with 'load_regressions'!

brain_area = 'c'; % 'ctx'/'c' or 'str'/'s'
cell_idx = 47;
model_no = 8;
split_no = 1;

switch brain_area
    case {'ctx', 'c'}
        brain_area = 'ctx';
        trace_by_trial = ctxstr.core.get_traces_for_cell(reg.binned_ctx_traces_by_trial, cell_idx);
        trace = reg.binned_ctx_traces(cell_idx,:);
        fd = reg.ctx_fit.data{cell_idx, model_no, split_no};

    case {'str', 's'}
        brain_area = 'str';
        trace_by_trial = ctxstr.core.get_traces_for_cell(reg.binned_str_traces_by_trial, cell_idx);
        trace = reg.binned_str_traces(cell_idx,:);
        fd = reg.str_fit.data{cell_idx, model_no, split_no};
end

% Show the detailed fit
figure(2); clf;
if isempty(fd)
    cprintf('red', 'Fit data is empty. Is the requested brain area correct?\n');
else
    fprintf('Visualizing %s-%s, Cell=%d...\n', reg.dataset_name, brain_area, cell_idx);
    
    ctxstr.analysis.regress.visualize_fit(...
                    reg.time_by_trial, trace_by_trial, fd.train_trial_inds, fd.test_trial_inds,...
                    reg.models{model_no}, fd.kernels, fd.biases, fd.train_results, fd.test_results,...
                    reg.t, reg.reward_frames, reg.motion_frames, reg.velocity, reg.accel, reg.lick_rate);
    title(sprintf('%s-%s, Cell=%d, model #=%d, split #=%d',...
                reg.dataset_name, brain_area, cell_idx, model_no, split_no));
end

% Show the cell raster
figure(3);
load('resampled_data.mat', 'st_trial_inds', 'trials');
ctxstr.vis.show_aligned_binned_raster(st_trial_inds, trials, trace, reg.t);
title(sprintf('%s-%s, Cell %d', reg.dataset_name, brain_area, cell_idx));

