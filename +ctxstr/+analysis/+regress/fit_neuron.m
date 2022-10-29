function [kernels, train_info, test_info] = fit_neuron(traces_by_trial, cell_idx, model, train_trial_inds, test_trial_inds, alpha, lambdas)

if exist('lambdas', 'var')
    lambdas = sort(lambdas, 'descend'); % glmnet wants lambdas in descending order
else
    lambdas = []; % glmnet will decide the lambda values
end


% Fit model to training data using glmnet
%------------------------------------------------------------
traces_train = ctxstr.core.concatenate_trials(traces_by_trial, train_trial_inds)'; % [num_frames x num_cells]

y_train = traces_train(:,cell_idx);

% FIXME: Note that build_design_matrix actually adds a column of ones at
% the end to fit the DC offset. This isn't the most "clean" approach when
% when using the glmnet package. The fix would be to get rid of the bias
% column in build_design_matrix, and modify the bernoulli_nll function to
% accept the bias term as a parameter separate from the weights.
X_train = ctxstr.analysis.regress.build_design_matrix(model, train_trial_inds); % [num_frames x num_preds]

options = glmnetSet;
options.alpha = alpha; % Elastic net param: 0==ridge, 1==lasso
options.lambda = lambdas;
options.standardize = false;
fit = glmnet(X_train, y_train, 'binomial', options);

w_opts = fit.beta;
w_opts(end,:) = fit.a0; % Fill in bias terms
train_R2s = fit.dev;
y_train_fits = glmnetPredict(fit, X_train, [], 'response');

% Parse w_opt into individual kernels.
%------------------------------------------------------------
num_regressors = length(model);
kernels = cell(1, num_regressors+1);

ind = 1;
for k = 1:num_regressors
    r = model{k};
    % In case we used temporal basis functions, convert the weights into an
    % actual kernel function in time. TODO: Save weights too?
    kernels{k} = r.basis_vectors' * w_opts(ind:ind+r.num_dofs-1,:);
    ind = ind + r.num_dofs;
end
kernels{end} = w_opts(end,:);

% Fit null model (i.e. constant predictor) to training data
[~, w_null] = ctxstr.analysis.regress.compute_null_model(y_train);

train_info = pack_info(y_train, fit.lambda, y_train_fits, train_R2s);
train_info.w_null = w_null;

train_info.fitobj = fit;

% Evaluate fit using on test data
%------------------------------------------------------------

traces_test = ctxstr.core.concatenate_trials(traces_by_trial, test_trial_inds)';

y_test = traces_test(:,cell_idx);
X_test = ctxstr.analysis.regress.build_design_matrix(model, test_trial_inds);

y_test_fits = glmnetPredict(fit, X_test, [], 'response');

num_lambdas = length(fit.lambda);
test_nlls = zeros(1,num_lambdas);
for j = 1:num_lambdas
    test_nlls(j) = ctxstr.analysis.regress.bernoulli_nll(w_opts(:,j), X_test, y_test);
end

% Evaluate the null model on testing data. Note that we're not fitting a
% new null model to the test data, but applying the null model from the
% training data to the test data.
test_nll_null = ctxstr.analysis.regress.bernoulli_nll(w_null, ones(size(y_test)), y_test);
test_R2s = 1 - test_nlls / test_nll_null;

test_info = pack_info(y_test, fit.lambda, y_test_fits, test_R2s);

% For convenience. TODO: Consider other output formats
[~, best_ind] = max(test_info.R2);
test_info.best_ind = best_ind;

end

function info = pack_info(y, lambdas, y_fits, R2s)
    info.y = y;
    info.lambdas = lambdas;
    info.y_fits = y_fits;
    info.R2 = R2s;
end
