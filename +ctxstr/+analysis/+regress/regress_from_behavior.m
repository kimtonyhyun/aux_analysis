function [fitted_traces, fit_info] = regress_from_behavior(traces_by_trial, t, trials, st_trial_inds, regressors)
% 'regressors' is a struct array with the following fields:
%   - regressors(k).name: Name of the regressor, e.g. "reward",;
%   - regressors(k).trace: Regressor trace, e.g. reward_frames, velocity;
%   - regressors(k).pre_samples: Num past samples to consider when
%       computing each output frame;
%   - regressors(k).post_samples: Num future samples to consider when
%       computing each output frame;

num_regressors = length(regressors);

% Generate temporally offset versions of each regressor
%------------------------------------------------------------
X = cell(num_regressors, 1);
num_dof_per_regressor = zeros(num_regressors, 1);
for k = 1:num_regressors
    r = regressors(k);
    X{k} = ctxstr.analysis.regress.generate_temporally_offset_regressors(...
        r.trace, r.pre_samples, r.post_samples);
    num_dof_per_regressor(k) = size(X{k}, 1);
end

% Regression will be performed over ST trials. Prepare the design matrix X
% accordingly.
%------------------------------------------------------------
X_st = cell(num_regressors, 1);
for k = 1:num_regressors
    Xk_by_trial = ctxstr.core.parse_into_trials(X{k}, t, trials);
    X_st{k} = ctxstr.core.concatenate_trials(Xk_by_trial, st_trial_inds);
end

X = cell2mat(X_st)'; % [num_frames x num_regressors]
y = ctxstr.core.concatenate_trials(traces_by_trial, st_trial_inds)'; % [num_frames x num_cells]

theta = (X'*X)\X'*y; % [num_regressors x num_cells]

fitted_traces = (X*theta)'; % [num_cells x num_frames]

% Package auxiliary information.
%------------------------------------------------------------
T = t(2) - t(1); % Deduce frame period from provided time

fit_info = repmat(struct('name', [],...
                         'pre_samples', [],...
                         'post_samples', [],...
                         't', [],...
                         'kernel', [],...
                         'num_dofs', []), num_regressors, 1);

idx = 1; % To parse theta into individual kernels
for k = 1:num_regressors
    r = regressors(k);
    fit_info(k).name = r.name;
    fit_info(k).pre_samples = r.pre_samples;
    fit_info(k).post_samples = r.post_samples;
    fit_info(k).t = T*(-r.pre_samples:r.post_samples);
    fit_info(k).num_dofs = num_dof_per_regressor(k);
    
    fit_info(k).kernel = theta(idx:idx+num_dof_per_regressor(k)-1,:)'; % [num_cells x pre:post]
    idx = idx + num_dof_per_regressor(k);
end
