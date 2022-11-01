function [kernels, biases, train_info, test_info] = fit_neuron(traces_by_trial, model, train_trial_inds, test_trial_inds, alpha, lambdas)

if exist('lambdas', 'var')
    lambdas = sort(lambdas, 'descend'); % glmnet wants lambdas in descending order
else
    lambdas = []; % glmnet will decide the lambda values
end


% Fit model to training data using glmnet
%------------------------------------------------------------
y_train = ctxstr.core.concatenate_trials(traces_by_trial, train_trial_inds)'; % [num_frames x 1]
X_train = ctxstr.analysis.regress.build_design_matrix(model, train_trial_inds); % [num_frames x num_preds]

options = glmnetSet;
options.alpha = alpha; % Elastic net param: 0==ridge, 1==lasso
options.lambda = lambdas;
options.standardize = false;
fit = glmnet(X_train, y_train, 'binomial', options);

w_opts = fit.beta;
biases = fit.a0; % Fill in bias terms
train_R2s = fit.dev;
y_train_fits = glmnetPredict(fit, X_train, [], 'response');

% Parse w_opt into individual kernels.
%------------------------------------------------------------
kernels = cell(1, model.num_regressors);

ind = 1;
for k = 1:model.num_regressors
    r = model.regressors{k};
    % In case we used temporal basis functions, convert the weights into an
    % actual kernel function in time. TODO: Save weights too?
    kernels{k} = r.basis_vectors' * w_opts(ind:ind+r.num_dofs-1,:);
    ind = ind + r.num_dofs;
end

% Fit null model (i.e. constant predictor) to training data
[~, w_null] = ctxstr.analysis.regress.compute_null_model(y_train);

% Evaluate fit using on test data
%------------------------------------------------------------

y_test = ctxstr.core.concatenate_trials(traces_by_trial, test_trial_inds)';
X_test = ctxstr.analysis.regress.build_design_matrix(model, test_trial_inds);

y_test_fits = glmnetPredict(fit, X_test, [], 'response');

num_lambdas = length(fit.lambda);
test_nlls = zeros(1,num_lambdas);
for j = 1:num_lambdas
    test_nlls(j) = ctxstr.analysis.regress.compute_bernoulli_nll(...
        y_test, X_test, w_opts(:,j), biases(j));
end

% Evaluate the null model on testing data. Note that we're not fitting a
% new null model to the test data, but applying the null model from the
% training data to the test data.
test_nll_null = ctxstr.analysis.regress.compute_bernoulli_nll(...
    y_test, 0, 0, w_null);
test_R2s = 1 - test_nlls / test_nll_null;
[~, best_fit_ind] = max(test_R2s);

% Package outputs. For kernels and y_fits, we're returning only the best
% performing model. This is in an effort to reduce the size in memory of
% the fit result (esp. with 'fit_all_neurons.m' in mind).
%------------------------------------------------------------
for k = 1:model.num_regressors
    kernels{k} = single(kernels{k}(:,best_fit_ind));
end

% On the other hand, we'll return the full bias curve as a function of
% lambda, because it's not very large in memory and we use this curve as an
% indication that the regularization worked (i.e. as lambda gets large, the
% bias curve should approach w_null).
biases = single(biases);

test_info = pack_info(fit.lambda, y_test_fits(:,best_fit_ind), test_R2s);
test_info.best_fit_ind = uint16(best_fit_ind); % For convenience

train_info = pack_info(fit.lambda, y_train_fits(:,best_fit_ind), train_R2s);
train_info.w_null = single(w_null);

% train_info.fitobj = fit; % glmnet output object

end

function info = pack_info(lambdas, y_fits, R2s)
    info.lambdas = single(lambdas);
    info.y_fits = single(y_fits);
    info.R2 = single(R2s);
end
