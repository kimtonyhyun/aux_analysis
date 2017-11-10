function test_scores = compute_logistic_test_scores(pre_features, post_features)
% Compute test scores multiple times by resampling training and test data
%
% Format:
%   pre_features: [num_examples x num_features]
%   post_features: [num_examples x num_features]
%

num_runs = 10;
training_frac = 0.7;

num_pre = size(pre_features, 1);
num_post = size(post_features, 1);

num_pre_train = round(training_frac * num_pre);
num_pre_test = num_pre - num_pre_train;
num_post_train = round(training_frac * num_post);
num_post_test = num_post - num_post_train;
num_test = num_pre_test + num_post_test;

test_scores = zeros(num_runs,1);
for r = 1:num_runs
    % Get a random train/test split
    pre_train = randperm(num_pre) <= num_pre_train;
    pre_test = ~pre_train;
    post_train = randperm(num_post) <= num_post_train;
    post_test = ~post_train;
    
    % Fit logistic regression to training data
    f_train = [pre_features(pre_train,:); post_features(post_train,:)];
    y_train = [zeros(1,num_pre_train) ones(1,num_post_train)]'; % Note: 0 <==> Pre, 1 <==> Post
    w = fit_logistic_regression(f_train, y_train);
    
    % Evaluate on training data
    f_test = [pre_features(pre_test,:); post_features(post_test,:)];
    y_test = [zeros(1,num_pre_test) ones(1,num_post_test)]';
    y_pred = make_prediction(w, f_test);
    
    test_scores(r) = sum(y_pred == y_test) / num_test;
end