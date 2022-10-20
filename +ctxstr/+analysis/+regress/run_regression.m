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

% Low-pass filtering
cutoff_freq = 7; % Hz
v_filt = ctxstr.analysis.filter_trace(velocity, cutoff_freq, fps);
a_filt = ctxstr.analysis.filter_trace(accel, cutoff_freq, fps);
lr_filt = ctxstr.analysis.filter_trace(lick_rate, cutoff_freq, fps);

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
ctxstr.analysis.regress.visualize_behavioral_regressors(trials, st_trial_inds, t,...
    velocity, v_filt,...
    accel, a_filt,...
    lick_times, lick_rate, lr_filt,...
    reward_frames, motion_frames);
title(sprintf('%s: All behavioral regressors', dataset_name));

%% Split ST trials into training and test

num_st_trials = length(st_trial_inds);
test_trial_inds = st_trial_inds(3:3:end); % Every third trial is a test trial
train_trial_inds = setdiff(st_trial_inds, test_trial_inds);

num_test = length(test_trial_inds);
num_train = length(train_trial_inds);

fprintf('%s: %d ST trials split into %d training trials and %d test trials\n',...
    dataset_name, num_st_trials, num_train, num_test);

%% Define regressors to be used in regression analysis

velocity_regressor = ctxstr.analysis.regress.define_regressor('velocity', velocity, 5, 5, t, trials);
accel_regressor = ctxstr.analysis.regress.define_regressor('accel', accel, 5, 5, t, trials);
lick_regressor = ctxstr.analysis.regress.define_regressor('lick_rate', lick_rate, 5, 5, t, trials);

reward_regressor = ctxstr.analysis.regress.define_regressor('reward', reward_frames, 15, 15, t, trials);
motion_regressor = ctxstr.analysis.regress.define_regressor('motion', motion_frames, 15, 15*3, t, trials);

%% Define model

% model = {velocity_regressor, accel_regressor, lick_regressor, motion_regressor, reward_regressor};
model = {accel_regressor};
num_regressors = length(model);

%% Define model and run regression

cell_idx = 10;

lambdas = 0:0.25:10;
[kernels, train_info, test_info] = ctxstr.analysis.regress.fit_neuron(...
    binned_str_traces_by_trial, cell_idx,...
    model,...
    train_trial_inds, test_trial_inds, lambdas);

%%

[~, best_ind] = max(test_info.R2);

subplot(4,2,1);
plot(train_info.lambdas, train_info.R2, '.-');
xlabel('\lambda');
ylabel({'Train R^2', '(Higher is better)'});
title(sprintf('%s Cell = %d', dataset_name, cell_idx));

subplot(4,2,2);
plot(test_info.lambdas, test_info.R2, '.-');
hold on;
plot(test_info.lambdas(best_ind), test_info.R2(best_ind), 'ro');
hold off;
xlabel('\lambda');
ylabel('Test R^2');
title(sprintf('Optimal R^2=%.4f', test_info.R2(best_ind)));

ax1 = subplot(4,1,2);
plot(train_info.y, 'k-');
hold on;
plot(train_info.y_fits(:,best_ind), 'r');
hold off;
ylim([-0.1 1.1]);

ylabel('Training fit');
grid on;
zoom xon;

ax2 = subplot(4,1,3);
plot(test_info.y, 'k-');
hold on;
plot(test_info.y_fits(:,best_ind), 'r');
hold off;
ylim([-0.1 1.1]);
ylabel('Test fit');
grid on;
zoom xon;

set([ax1 ax2], 'TickLength', [0 0]);

for k = 1:num_regressors
    subplot(4, num_regressors, 3*num_regressors + k);
    r = model{k};
    plot(r.t_kernel, kernels{k}(:,best_ind), 'r.-');
    hold off;
    title(r.name, 'Interpreter', 'none');
    xlim(r.t_kernel([1 end]));
    grid on;
    xlabel('Time (s)');
end
