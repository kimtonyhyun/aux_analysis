function [w_opt, train_info, test_info] = fit_neuron(traces_by_trial, cell_idx, regressors, train_trial_inds, test_trial_inds)

traces_train = ctxstr.core.concatenate_trials(traces_by_trial, train_trial_inds)'; % [num_frames x num_cells]

y_train = traces_train(:,cell_idx);
X_train = build_design_matrix(regressors, train_trial_inds);

% Define the log likelihood function and optimize
%------------------------------------------------------------
nll_fun = @(w) ctxstr.analysis.regress.bernoulli_nll(w, X_train, y_train);

% Regularization
Imat = eye(size(X_train,2));
Imat(end,end) = 0; % No regularization penalty for DC term
Cinv = 0*Imat;

reg_nll_fun = @(w) ctxstr.analysis.regress.neglogposterior(w, nll_fun, Cinv);

opts = optimoptions(@fminunc, 'Algorithm', 'trust-region',...
    'GradObj', 'on', 'Hessian', 'on', 'Display', 'iter-detailed');

w_init = zeros(size(X_train,2), 1);
[w_opt, nll_opt] = fminunc(reg_nll_fun, w_init, opts);

train_info = pack_info(y_train,...
                       sigmoid(X_train*w_opt),...
                       nll_opt,...
                       compute_null_model_nll(y_train));
                   
% TODO: Convert w_opt into individual kernels
                       
% Evaluate fit using on test data
%------------------------------------------------------------

traces_test = ctxstr.core.concatenate_trials(traces_by_trial, test_trial_inds)';

y_test = traces_test(:,cell_idx);
X_test = build_design_matrix(regressors, test_trial_inds);

test_info = pack_info(y_test,...
                      sigmoid(X_test*w_opt),...
                      ctxstr.analysis.regress.bernoulli_nll(w_opt, X_test, y_test),...
                      compute_null_model_nll(y_test));

end

function X = build_design_matrix(regressors, trial_inds)
    num_regressors = length(regressors);

    Xs = cell(num_regressors+1, 1); % Extra term for DC offset
    for k = 1:num_regressors
        r = regressors{k};
        Xs{k} = ctxstr.core.concatenate_trials(r.X_by_trial, trial_inds);
    end
    Xs{end} = ones(1,size(Xs{1},2)); % DC offset
    X = cell2mat(Xs)'; % [num_frames x num_regressor_dofs]
end

function y = sigmoid(proj)
    y = 1./(1+exp(-proj));
end

function nll_null = compute_null_model_nll(y)
    n = length(y) + 2; % Pretend we observed 0 and 1 at least once
    m = sum(y) + 1;
    w_null = log(m/(n-m));
    nll_null = ctxstr.analysis.regress.bernoulli_nll(w_null, ones(size(y)), y);
end

function info = pack_info(y, y_fit, nll_fit, nll_null)
    info.y = y;
    info.y_fit = y_fit;
    info.nll_fit = nll_fit;
    info.nll_null = nll_null;
    info.R2 = 1 - nll_fit/nll_null;
end
