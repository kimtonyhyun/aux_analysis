function [negLP,grad,H] = neglogelasticnet(prs,negloglifun,C1,C2)
% [negLP,grad,H] = neglogposterior(prs,negloglifun,Cinv)
%
% Compute negative log-posterior given a negative log-likelihood function
% and zero-mean Gaussian prior with inverse covariance 'Cinv'.
%
% Inputs:
%    prs [d x 1] - parameter vector
%    negloglifun - handle for negative log-likelihood function
%    C1 [d x 1] - L1 regularization
%    C2 [d x d] - L2 regularization
%
% Outputs:
%          negLP - negative log posterior
%   grad [d x 1] - gradient 
%      H [d x d] - Hessian (second deriv matrix)

% Compute negative log-posterior by adding quadratic penalty to log-likelihood

% THK, 2022 Oct 28:
%   Based on J. Pillow's 'neglogposterior' function

% alpha == 1 corresponds to L1 regularization, alpha == 0 to L2 regularization
alpha = 0.95;

switch nargout

    case 1  % evaluate function
        negLP = negloglifun(prs) +...
                    alpha * C1'*abs(prs) +...
                    (1-alpha) * .5*prs'*C2*prs;
    
    case 2  % evaluate function and gradient
        [negLP,grad] = negloglifun(prs);
        negLP = negLP + alpha * C1'*abs(prs) + (1-alpha) * .5*prs'*C2*prs;
        grad = grad + alpha * C1.*sign(prs) + (1-alpha) * C2*prs;

    case 3  % evaluate function and gradient
        [negLP,grad,H] = negloglifun(prs);
        negLP = negLP + alpha * C1'*abs(prs) + (1-alpha) * .5*prs'*C2*prs;
        grad = grad + alpha * C1.*sign(prs) + (1-alpha) * C2*prs;
        H = H + C2;
end

