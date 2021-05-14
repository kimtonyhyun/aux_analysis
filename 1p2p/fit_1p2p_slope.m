function [slope, info] = fit_1p2p_slope(tr2, tr1)
% Assumes:
%   - tr2: z-scored 2P trace
%   - tr1: z-scored 1P trace

% Fit a polynomial curve to the 1P/2P scatter plot
order = 2;
zsc_thresh = 3;

% Exclude the baseline portions from fitting
mask1 = (tr1 > zsc_thresh);
mask2 = (tr2 > zsc_thresh);
mask = mask1 | mask2;

% mask = true(length(tr1),1); % Debug: Use all samples for fit

if sum(mask) <= order
    slope = [];
    info = [];
else
    p = polyfitZero(tr2(mask), tr1(mask), order);
%     p = polyfit(tr2(mask), tr1(mask), order);
    x = linspace(min(tr2), max(tr2));
    y = polyval(p, x);

    % Fraction of variance explained. Note that if polyfitZero is used, the
    % fve can be negative
    tr1_fit = polyval(p, tr2);
    fve = 1 - var(tr1(mask)-tr1_fit(mask))/var(tr1(mask));
    
    % Evaluate slope of fit
    pd = polyder(p);
    xd = 1/3*max(tr2); % Evaluate at 33.3% of the dynamic range
    slope = polyval(pd, 1/3*max(tr2));

    % Package for output
    info.fit.zsc_thresh = zsc_thresh;
    info.fit.mask = mask;
    info.fit.order = order;
    info.fit.x = x;
    info.fit.y = y;
    info.fit.fve = fve;
    info.xd = xd; % Evaluation point for the derivative
end