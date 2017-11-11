function w = fit_logistic_regression(f_train, y_train)
% Fit logistic regression model. Formats:
%
% f_train: [num_examples x num_features]
% y_train: [num_examples x 1], assumed to be 0 or 1
%
% w: [1 x (num_features + 1)], bias term is w(end)

[num_examples, num_features] = size(f_train);
f = [f_train ones(num_examples,1)]; % Add bias term

w0 = randn(1, num_features+1);
cost_fun = @(w) cost(w, f, y_train);

options = optimoptions('fminunc',...
    'Algorithm', 'trust-region',...
    'SpecifyObjectiveGradient', true,...
    'Display', 'off');

w = fminunc(cost_fun, w0, options);

end % fit_logistic_regression

function [f, g] = cost(w, X, y)
    % Cost function is negative log likelihood
    h = sigmoid(X*w');
    f = -sum([log(h(y==1)); log(1-h(y==0))]);
    
    if nargout > 1 % gradient
        g = -(y - h)'*X; % g is a row vector
    end
end % cost
