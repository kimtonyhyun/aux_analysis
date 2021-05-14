function [slope, info] = fit_1p2p(tr1, tr2)
% Inputs:
%   - tr1: z-scored 1P trace
%   - tr2: z-scored 2P trace

% Parameters
order = 2; % Allow for quadratic fits
zsc_thresh = 3;
fit_thresh = 3;

% Exclude the baseline portions from fitting. The baseline points can skew
% the slope of the fit, and will bias metrics such as fraction of frames
% where the fit is "good".
mask1 = (tr1 > zsc_thresh);
mask2 = (tr2 > zsc_thresh);
mask = mask1 | mask2;

% mask = true(length(tr1),1); % Debug: Use all samples for fitting

num_fit_frames = sum(mask);

if sum(mask) <= order
    slope = [];
    info = [];
else
    p = polyfitZero(tr2(mask), tr1(mask), order); % Forces interecept at origin
%     p = polyfit(tr2(mask), tr1(mask), order);
    x = linspace(min(tr2), max(tr2));
    y = polyval(p, x);

    % Fraction of variance explained (FVE). Note that if polyfitZero is
    % used, the fve can be negative.
    tr1_fit = polyval(p, tr2);
    fve = 1 - var(tr1(mask)-tr1_fit(mask))/var(tr1(mask));
    
    % Fraction of frames with a "good" fit
    fit_error = abs(tr1 - tr1_fit);
    num_good_frames = sum(fit_error(mask) < fit_thresh);
    fraction_good_fit = num_good_frames / num_fit_frames;
    
    % Evaluate slope of fit
    pd = polyder(p);
    xd = 1/3*max(tr2); % Evaluate at 33.3% of the dynamic range
    slope = polyval(pd, 1/3*max(tr2));

    % Package for output
    %------------------------------------------------------------
    info.params.order = order;
    info.params.zsc_thresh = zsc_thresh;
    info.params.fit_thresh = fit_thresh;
    
    info.fit.mask = mask;
    info.fit.num_fit_frames = num_fit_frames;
    info.fit.x = x;
    info.fit.y = y;
    
    info.metric.fraction_variance_explained = fve;
    info.metric.fraction_good_fit = fraction_good_fit;
    
    info.xd = xd; % Evaluation point for the derivative
end