function [train, test, inds] = split_train_test(pre_features, post_features, training_frac)
% Split the data into training and testing sets at the desired training
% fraction. Sample uniformly from PRE and POST examples.
%
% Format:
%   pre_features: [num_pre_examples x num_features]
%   post_features: [num_post_examples x num_features]
%
num_pre = size(pre_features, 1);
num_post = size(post_features, 1);

num_pre_train = round(training_frac * num_pre);
num_pre_test = num_pre - num_pre_train;
num_post_train = round(training_frac * num_post);
num_post_test = num_post - num_post_train;

% Get a random train/test split
pre_train = randperm(num_pre) <= num_pre_train;
pre_test = ~pre_train;
post_train = randperm(num_post) <= num_post_train;
post_test = ~post_train;

% Format output as structs
train = struct(...
    'X', [pre_features(pre_train,:); post_features(post_train,:)],...
    'y', [zeros(num_pre_train,1); ones(num_post_train,1)],...
    'n', num_pre_train + num_post_train);

test = struct(...
    'X', [pre_features(pre_test,:); post_features(post_test,:)],...
    'y', [zeros(num_pre_test,1); ones(num_post_test,1)],...
    'n', num_pre_test + num_post_test);

inds.pre.train = pre_train;
inds.pre.test = pre_test;
inds.post.train = post_train;
inds.post.test = post_test;