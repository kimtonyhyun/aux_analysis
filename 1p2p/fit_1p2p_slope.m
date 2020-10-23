function [slope, info] = fit_1p2p_slope(tr2, tr1)
% Assumes:
%   - tr2: z-scored 2P trace
%   - tr1: z-scored 1P trace

% Fit a polynomial curve to the 1P/2P scatter plot
order = 2;
mask = (tr2 > 3); % The cloud of points near the origin skews the fit
p = polyfitZero(tr2(mask), tr1(mask), order);
x = linspace(min(tr2), max(tr2));
y = polyval(p, x);

% Evaluate slope of fit
pd = polyder(p);
xd = 1/3*max(tr2); % Evaluate at 33.3% of the dynamic range
slope = polyval(pd, 1/3*max(tr2));

% Package for output
info.fit.order = order;
info.fit.x = x;
info.fit.y = y;
info.xd = xd; % Evaluation point for the derivative