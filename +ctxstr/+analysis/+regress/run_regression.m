clear;

load('resampled_data.mat');

bin_threshold = 0.2;

[binned_ctx_traces, binned_ctx_traces_by_trial] = ...
    ctxstr.core.binarize_traces(ctx_traces, ctx_traces_by_trial, bin_threshold);

[binned_str_traces, binned_str_traces_by_trial] = ...
    ctxstr.core.binarize_traces(str_traces, str_traces_by_trial, bin_threshold);

%% Resample continuous behavioral regressors to neural data sampling rate

% Note: the original velocity calculation is performed at 10 Hz, so the
% interpolation below upsamples the original data.
velocity = interp1(session.behavior.velocity(:,1), session.behavior.velocity(:,2), t);
accel = ctxstr.analysis.compute_derivative(t, velocity);

lick_times = session.behavior.lick_times;
lick_rate = ctxstr.behavior.compute_lick_rate(lick_times, t, 0.25);

% Normalize
velocity = velocity / max(abs(velocity));
accel = accel / max(abs(accel));
lick_rate = lick_rate / max(lick_rate);

%% Resample event-type behavioral regressors to neural data sampling rate

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

%% Split ST trials into training and test

num_st_trials = length(st_trial_inds);
test_trial_inds = st_trial_inds(3:3:end); % Every third trial is a test trial
train_trial_inds = setdiff(st_trial_inds, test_trial_inds);

num_test = length(test_trial_inds);
num_train = length(train_trial_inds);

fprintf('%s: %d ST trials split into %d training trials and %d test trials\n',...
    dataset_name, num_st_trials, num_train, num_test);

%% Define regression model

velocity_regressor = ctxstr.analysis.regress.define_regressor('velocity', velocity, 5, 45, t, trials);
accel_regressor = ctxstr.analysis.regress.define_regressor('accel', accel, 5, 15, t, trials);
lick_regressor = ctxstr.analysis.regress.define_regressor('lick_rate', lick_rate, 5, 5, t, trials);

reward_regressor = ctxstr.analysis.regress.define_regressor('reward', reward_frames, 0, 15, t, trials);
motion_regressor = ctxstr.analysis.regress.define_regressor('motion', motion_frames, 15, 30, t, trials);

% model = {motion_regressor, reward_regressor};
model = {velocity_regressor};

%% Define model and run regression

brain_area = 'str'; % 'ctx' or 'str'
cell_idx = 23;

switch brain_area
    case 'ctx'
        binned_traces_by_trial = binned_ctx_traces_by_trial;
    case 'str'
        binned_traces_by_trial = binned_str_traces_by_trial;
end

lambdas = 0:0.25:10;
[kernels, train_results, test_results] = ctxstr.analysis.regress.fit_neuron(...
    binned_traces_by_trial, cell_idx,...
    model,...
    train_trial_inds, test_trial_inds, lambdas);

%%

% figure;
ctxstr.analysis.regress.visualize_fit(...
    time_by_trial, train_trial_inds, test_trial_inds,...
    model, kernels, train_results, test_results,...
    t, reward_frames, motion_frames, velocity, accel, lick_rate);
title(sprintf('%s-%s, Cell %d', dataset_name, brain_area, cell_idx));

%%

best_ind = test_results.best_ind;
visualize_step_response(model{1}, kernels{1}(:,best_ind));