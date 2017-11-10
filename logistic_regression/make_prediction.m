function y = make_prediction(w, f)
% Make binary predictions based on logistic regression fit. Formats
%
% w: [1 x (num_features + 1)], bias term is w(end)
% f: [num_examples x num_features]. Bias term will be added
%

n = size(f,1);
x = [f ones(n,1)]; % Add bias term
y = sigmoid(x*w') > 0.5;