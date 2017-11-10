function ll = loglikelihood(w, x, y)
% Format:
%   w: [1 x num_features+1]. w(end) is the bias term
%   x: [num_examples x num_features]. Bias term will be added internally
%   y: [num_examples x 1]. Labels, should be 0 or 1.

num_examples = size(x, 1);
x = [x ones(num_examples, 1)]; % Add bias term

h = sigmoid(x*w');

ll = sum([log(h(y==1)); log(1-h(y==0))]);