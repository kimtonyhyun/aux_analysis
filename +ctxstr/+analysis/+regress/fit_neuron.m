function [kernels, train_info, test_info] = fit_neuron(traces_by_trial, cell_idx, model, train_trial_inds, test_trial_inds, lambdas)

if ~exist('lambdas', 'var') % Regularization weight
    lambdas = 0;
end
num_lambdas = length(lambdas);

num_regressors = length(model);

traces_train = ctxstr.core.concatenate_trials(traces_by_trial, train_trial_inds)'; % [num_frames x num_cells]

y_train = traces_train(:,cell_idx);
n_train = length(y_train);
X_train = build_design_matrix(model, train_trial_inds);
num_dofs = size(X_train,2);

% Fit to the training data for each regularization weight
%------------------------------------------------------------

% Preallocate
w_opts = zeros(num_dofs, num_lambdas);
y_train_fits = zeros(n_train, num_lambdas);
train_nlls = zeros(1, num_lambdas);

% Regularization

% If the regressor type is full rank, then the squared diff regularizer
% (below) is a reasonable one to try.
% D = build_squared_diff_matrix(model);

% Alternatively, if we are enforcing kernel smoothness by using smooth
% temporal basis functions, then L1 and/or L2 regularization on the weights
% make sense.
C1 = ones(num_dofs,1); % Lasso
C1(end) = 0; % No L1 penalty for bias term
C2 = eye(num_dofs); % Ridge
C2(end,end) = 0; % No L2 penalty for bias term
nll_fun = @(w) ctxstr.analysis.regress.bernoulli_nll(w, X_train, y_train);
w_init = zeros(num_dofs, 1);
opts = optimoptions(@fminunc, 'Algorithm', 'trust-region',...
    'GradObj', 'on', 'Hessian', 'on', 'Display', 'iter-detailed');

for j = 1:num_lambdas
    % Regularized log likelihood function
    reg_nll_fun = @(w) ctxstr.analysis.regress.neglogposterior(w, nll_fun, lambdas(j)*C2);
%     reg_nll_fun = @(w) ctxstr.analysis.regress.neglogelasticnet(w, nll_fun,...
%                         lambdas(j)*C1, lambdas(j)*C2);
    
    w_opts(:,j) = fminunc(reg_nll_fun, w_init, opts);
    y_train_fits(:,j) = sigmoid(X_train*w_opts(:,j));
    train_nlls(j) = nll_fun(w_opts(:,j)); % Note use of non-regularized NLL
    
    w_init = w_opts(:,j); % Use previously computed optimum as the initial guess for next run
end

% Parse w_opt into individual kernels.
kernels = cell(1, num_regressors+1);

ind = 1;
for k = 1:num_regressors
    r = model{k};
    % In case we used temporal basis functions, convert the weights into an
    % actual kernel function in time. TODO: Save weights too?
    kernels{k} = r.basis_vectors' * w_opts(ind:ind+r.num_dofs-1,:);
    ind = ind + r.num_dofs;
end
kernels{end} = w_opts(end,:); % Bias term

% Fit null model (i.e. constant predictor) to training data
[train_nll_null, w_null] = ctxstr.analysis.regress.compute_null_model(y_train);

train_info = pack_info(y_train, lambdas, y_train_fits, train_nlls, train_nll_null);
train_info.w_null = w_null;

% Evaluate fit using on test data
%------------------------------------------------------------

traces_test = ctxstr.core.concatenate_trials(traces_by_trial, test_trial_inds)';

y_test = traces_test(:,cell_idx);
n_test = length(y_test);
X_test = build_design_matrix(model, test_trial_inds);

% Preallocate
y_test_fits = zeros(n_test, num_lambdas);
test_nlls = zeros(1, num_lambdas);

for j = 1:num_lambdas
    y_test_fits(:,j) = sigmoid(X_test*w_opts(:,j));
    test_nlls(j) = ctxstr.analysis.regress.bernoulli_nll(w_opts(:,j), X_test, y_test);
end

% Evaluate the null model on testing data
test_nll_null = ctxstr.analysis.regress.bernoulli_nll(w_null, ones(size(y_test)), y_test);

test_info = pack_info(y_test, lambdas, y_test_fits, test_nlls, test_nll_null);

% For convenience. TODO: Consider other output formats
[~, best_ind] = max(test_info.R2);
test_info.best_ind = best_ind;

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

function D = build_squared_diff_matrix(regressors)
    % Generate a matrix D such that w'*D*w computes the squared differences
    % between adjacent elements of each kernel. Code was based on Pillow's
    % 'GLMspiketraintutorial' Git repository.
    num_regressors = length(regressors);
    
    Ds = cell(num_regressors+1, 1); % Extra term for DC offset
    for k = 1:num_regressors
        r = regressors{k};
        nr = r.num_dofs;
        
        % This matrix computes differences between adjacent coeffs
        Dx1 = spdiags(ones(nr,1)*[-1 1], 0:1, nr-1, nr);
        Ds{k} = Dx1'*Dx1; % Computes squared diffs
    end
    
    D = [];
    for k = 1:num_regressors
        D = blkdiag(D, Ds{k});
    end
    D = blkdiag(D,0); % Last row/col for the DC offset
end

function info = pack_info(y, lambdas, y_fits, nlls, nll_null)
    info.y = y;
    info.lambdas = lambdas;
    info.y_fits = y_fits;
    info.nlls = nlls;
    info.nll_null = nll_null;
    info.R2 = 1 - nlls/nll_null;
end
