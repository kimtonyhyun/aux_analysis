clear;

load('resampled_data.mat');

% Load neural data (CASCADE traces) and binarize
%----------------------------------------------------------------------
bin_threshold = 0.2;

[binned_ctx_traces, binned_ctx_traces_by_trial] = ...
    ctxstr.core.binarize_traces(ctx_traces, ctx_traces_by_trial, bin_threshold);

[binned_str_traces, binned_str_traces_by_trial] = ...
    ctxstr.core.binarize_traces(str_traces, str_traces_by_trial, bin_threshold);

% Resample continuous behavioral regressors to neural data sampling rate
%----------------------------------------------------------------------

% Note: the original velocity calculation is performed at 10 Hz, so the
% interpolation below upsamples the original data. Consider calculating
% velocity directly at a 15 Hz timebase.
velocity = interp1(session.behavior.velocity(:,1), session.behavior.velocity(:,2), t);
accel = ctxstr.analysis.compute_derivative(t, velocity);

lick_times = session.behavior.lick_times;
lick_rate = ctxstr.behavior.compute_lick_rate(lick_times, t, 0.25);

% Normalize
velocity = velocity / max(abs(velocity));
accel = accel / max(abs(accel));
lick_rate = lick_rate / max(lick_rate);

% Resample event-type behavioral regressors to neural data sampling rate
%----------------------------------------------------------------------

% Note: By filtering for reward and motion onset times from ST trials only,
% we prevent those events from non-ST trials from "leaking" into ST trials.
selected_reward_times = [];
selected_motion_times = [];
for trial_idx = st_trial_inds
    trial = trials(trial_idx);
    
    % For each stereotyped trial, we include the two US'es that define the
    % start and end of the trial. Duplicate entries are removed below.
    selected_reward_times = [selected_reward_times trial.start_time trial.us_time]; %#ok<*AGROW>
    selected_motion_times = [selected_motion_times trial.motion.onsets];
end
selected_reward_times = unique(selected_reward_times);

reward_frames = ctxstr.core.assign_events_to_frames(selected_reward_times, t);
motion_frames = ctxstr.core.assign_events_to_frames(selected_motion_times, t);

% Visualize all continuous and event-type behavioral regressors
% ctxstr.analysis.regress.visualize_behavioral_regressors(trials, st_trial_inds, t,...
%     velocity, accel,...
%     lick_times, lick_rate,...
%     reward_frames, motion_frames);
% title(sprintf('%s: All behavioral regressors', dataset_name));

cprintf('blue', 'Loaded "%s" data for regression analyses\n', dataset_name);

%% Kernels represented by smooth temporal basis functions

spacing = 3; % samples

velocity_regressor = ctxstr.analysis.regress.define_regressor_smooth('velocity', velocity, 3, 3, spacing, t, trials);
accel_regressor = ctxstr.analysis.regress.define_regressor_smooth('accel', accel, 3, 3, spacing, t, trials);
lick_regressor = ctxstr.analysis.regress.define_regressor_smooth('lick_rate', lick_rate, 3, 3, spacing, t, trials);

reward_regressor = ctxstr.analysis.regress.define_regressor_smooth('reward', reward_frames, 3, 3, spacing, t, trials);
motion_regressor = ctxstr.analysis.regress.define_regressor_smooth('motion', motion_frames, 3, 18, spacing, t, trials);

%% Compare models

generate_model = @(rs) ctxstr.analysis.regress.model(rs); % Shorthand

models = {generate_model(velocity_regressor);
          generate_model(accel_regressor);
          generate_model(lick_regressor);
          generate_model(motion_regressor);
          generate_model(reward_regressor);
          generate_model({motion_regressor, reward_regressor});
          generate_model({velocity_regressor, motion_regressor, reward_regressor});
          generate_model({velocity_regressor, accel_regressor, lick_regressor, motion_regressor, reward_regressor});
         };
num_models = length(models);

%% Select a single cell for analysis (see also run_regression_all.m)

brain_area = 'str'; % 'ctx' or 'str'
cell_idx = 124;

switch brain_area
    case 'ctx'
        binned_traces_by_trial = binned_ctx_traces_by_trial;
    case 'str'
        binned_traces_by_trial = binned_str_traces_by_trial;
end

num_active_trials = ctxstr.analysis.count_active_trials(cell_idx, binned_traces_by_trial, st_trial_inds);
num_st_trials = length(st_trial_inds);
cprintf('blue', '%s-%s, Cell %d\n', dataset_name, brain_area, cell_idx);
fprintf('- Shows activity in %d out of %d trials (%.1f%%)\n',...
    num_active_trials, num_st_trials, 100*num_active_trials/num_st_trials);

%%

num_splits = 10; % Number of training/test splits
R2_vals = zeros(num_models, num_splits);

alpha = 0.95; % Elastic net parameter (0==ridge; 1==lasso)
lambdas = []; % lets glmnet explore regularization weights

% We will be makig lots of figures, one for each train/test split, so it's
% convenient to dock all figures.
set(0, 'DefaultFigureWindowStyle', 'docked');

for model_no = 1:num_models
    model = models{model_no};
    fprintf('- Model no=%d (%s): ', model_no, model.get_desc);
    for split_no = 1:num_splits
        [train_trial_inds, test_trial_inds] = ctxstr.analysis.regress.generate_train_test_trials(st_trial_inds, split_no);

        [kernels, train_results, test_results] = ctxstr.analysis.regress.fit_neuron(...
            binned_traces_by_trial, cell_idx,...
            model,...
            train_trial_inds, test_trial_inds, alpha, lambdas);
        
        % Store the optimal test R2
        R2_vals(model_no, split_no) = test_results.R2(test_results.best_ind);

        % Show regression results. Note, we show the plots only for the
        % first 3 splits, as these are deterministic and can be directly
        % compared across models.
        if split_no < 4
            fig_id = 10*model_no + split_no;
            figure(fig_id);
            clf;
            ctxstr.analysis.regress.visualize_fit(...
                time_by_trial, train_trial_inds, test_trial_inds,...
                model, kernels, train_results, test_results,...
                t, reward_frames, motion_frames, velocity, accel, lick_rate);
        end
        title(sprintf('%s-%s, Cell %d, \\alpha=%.2f, split=%d',...
            dataset_name, brain_area, cell_idx, alpha, split_no));
    end

    fprintf('R^2=%.3f+/-%.3f across %d train/test splits\n',...
        mean(R2_vals(model_no,:)),...
        std(R2_vals(model_no,:))/sqrt(num_splits),...
        num_splits);
end

%% Show cell raster (use for cross referencing cell identity)

switch brain_area
    case 'ctx'
        binned_traces = binned_ctx_traces;
    case 'str'
        binned_traces = binned_str_traces;
end

figure;
ctxstr.vis.show_aligned_binned_raster(st_trial_inds, trials, binned_traces(cell_idx,:), t);
title(sprintf('%s-%s, Cell %d', dataset_name, brain_area, cell_idx));

%% Fit all neurons

alpha = 0.95;
num_splits = 10;
active_frac_thresh = 0.1; % Only fit neurons that show activity on >10% of trials

[ctx_fit.results, ctx_fit.data] = ctxstr.analysis.regress.fit_all_neurons(binned_ctx_traces_by_trial, st_trial_inds, models, active_frac_thresh, alpha, num_splits);
[str_fit.results, str_fit.data] = ctxstr.analysis.regress.fit_all_neurons(binned_str_traces_by_trial, st_trial_inds, models, active_frac_thresh, alpha, num_splits);

