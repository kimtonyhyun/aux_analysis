function [test_scores, W] = compute_logistic_test_scores(pre_features, post_features, num_runs)
% Compute test scores multiple times by resampling training and test data
%
% Format:
%   pre_features: [num_examples x num_features]
%   post_features: [num_examples x num_features]
%

if nargin < 3
    num_runs = 20;
end

num_features = size(pre_features, 2);
training_frac = 0.7;

test_scores = zeros(num_runs,1);
W = zeros(num_runs, num_features + 1);
for r = 1:num_runs
    % Get a random train/test split
    [train, test] = split_train_test(pre_features, post_features, training_frac);
    
    % Fit logistic regression to training data
    w = fit_logistic_regression(train.X, train.y);
    
    % Evaluate on training data
    y_pred = make_prediction(w, test.X);
    
    W(r,:) = w;
    test_scores(r) = sum(y_pred == test.y) / test.n;
end