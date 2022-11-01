function nll = compute_bernoulli_nll(y, X, w, bias)
% Formats:
%   - y: [num_samples x 1]
%   - X: [num_samples x num_dofs]
%   - w: [num_dofs x 1]
%   - bias: [1 x 1]

xproj = X*w + bias*ones(size(y)); % Need bias vector, even if X or w = 0
nll = -y'*xproj + sum(softrect(xproj));
nll = nll / length(y);

% -------------------------------------------------------------
% ----- SoftRect Function (log-normalizer) --------------------
% -------------------------------------------------------------

function [f,df,ddf] = softrect(x)
%  [f,df,ddf] = softrect(x);
%
%  Computes: f(x) = log(1+exp(x))
%  and first and second derivatives

f = log(1+exp(x));

if nargout > 1
    df = exp(x)./(1+exp(x));
end
if nargout > 2
    ddf = exp(x)./(1+exp(x)).^2;
end

% Check for small values
if any(x(:)<-20)
    iix = (x(:)<-20);
    f(iix) = exp(x(iix));
    df(iix) = f(iix);
    ddf(iix) = f(iix);
end

% Check for large values
if any(x(:)>500)
    iix = (x(:)>500);
    f(iix) = x(iix);
    df(iix) = 1;
    ddf(iix) = 0;
end
