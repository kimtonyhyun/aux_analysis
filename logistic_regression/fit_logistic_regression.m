function [w, info] = fit_logistic_regression(f_train, y_train)
% Fit logistic regression model with homebrew SGD. Formats:
%
% f_train: [num_examples x num_features]
% y_train: [num_examples x 1]
%
% w: [1 x (num_features + 1)], bias term is w(end)
%

[n_train, n_features] = size(f_train);

num_epochs = 200;
alpha = 0.1;

w = rand(1, n_features+1);
W = zeros(num_epochs, n_features+1); % History
LL = zeros(num_epochs, 1);

for i = 1:num_epochs
    for j = randperm(n_train)
        ex_f = f_train(j,:);
        ex_y = y_train(j);
        
        pred = sigmoid(w*[ex_f 1]');
        w = w + alpha*(ex_y - pred)*[ex_f 1];
    end
    
    W(i,:) = w;
    LL(i) = loglikelihood(w, f_train, y_train);
end

% For debugging
info.num_epochs = num_epochs;
info.alpha = alpha;
info.W = W;
info.LL = LL;