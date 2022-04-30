function [traces_fit, fit_info] = regress_from_behavior(traces_by_trial, t, trials, st_trial_inds,...
    reward_frames, reward_pre_samples, reward_post_samples,...
    motion_frames, motion_pre_samples, motion_post_samples,...
    velocity, velocity_pre_samples, velocity_post_samples)

T = t(2) - t(1); % Deduce frame period from provided time

% Generate temporally offset regressors
%------------------------------------------------------------
X_reward = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
    reward_frames, reward_pre_samples, reward_post_samples); % [regressors x num_frames]
num_reward_regressors = size(X_reward, 1);

X_motion = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
    motion_frames, motion_pre_samples, motion_post_samples);
num_motion_regressors = size(X_motion, 1);

X_velocity = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
    velocity, velocity_pre_samples, velocity_post_samples);
num_velocity_regressors = size(X_velocity, 1);

% Regression will be performed over ST trials. Prepare the design matrix X
% accordingly.
%------------------------------------------------------------
X_reward_by_trial = ctxstr.core.parse_into_trials(X_reward, t, trials);
X_motion_by_trial = ctxstr.core.parse_into_trials(X_motion, t, trials);
X_velocity_by_trial = ctxstr.core.parse_into_trials(X_velocity, t, trials);

X_reward_st = ctxstr.core.concatenate_trials(X_reward_by_trial, st_trial_inds);
X_motion_st = ctxstr.core.concatenate_trials(X_motion_by_trial, st_trial_inds);
X_velocity_st = ctxstr.core.concatenate_trials(X_velocity_by_trial, st_trial_inds);

X = cat(1, X_reward_st, X_motion_st, X_velocity_st)'; % [num_frames x num_regressors]
y = ctxstr.core.concatenate_trials(traces_by_trial, st_trial_inds)'; % [num_frames x num_cells]

theta = (X'*X)\X'*y; % [num_regressors x num_cells]

traces_fit = (X*theta)'; % [num_cells x num_frames]

% Package auxiliary information.
%------------------------------------------------------------

k_idx = 1; % For parsing out theta into individual kernels
fit_info.reward.pre_samples = reward_pre_samples;
fit_info.reward.post_samples = reward_post_samples;
fit_info.reward.t = T*(-reward_pre_samples:reward_post_samples);
fit_info.reward.kernel = theta(k_idx:(k_idx+num_reward_regressors-1),:)'; % kernel(k,:) is the kernel for the k-th cell
fit_info.reward.num_regressors = num_reward_regressors;
% Indicator variables showing the finite support of each event. These
% variables can also be used for computing crude correlations between
% neural activity and behavior.
fit_info.reward.support = sum(X_reward,1) > 0;

k_idx = num_reward_regressors + 1;
fit_info.motion.pre_samples = motion_pre_samples;
fit_info.motion.post_samples = motion_post_samples;
fit_info.motion.t = T*(-motion_pre_samples:motion_post_samples);
fit_info.motion.kernel = theta(k_idx:(k_idx+num_motion_regressors-1),:)';
fit_info.motion.num_regressors = num_motion_regressors;
fit_info.motion.support = sum(X_motion,1) > 0;

k_idx = num_reward_regressors + num_motion_regressors + 1;
fit_info.velocity.pre_samples = velocity_pre_samples;
fit_info.velocity.post_samples = velocity_post_samples;
fit_info.velocity.t = T*(-velocity_pre_samples:velocity_post_samples);
fit_info.velocity.kernel = theta(k_idx:(k_idx+num_velocity_regressors-1),:)';
fit_info.velocity.num_regressors = num_velocity_regressors;
