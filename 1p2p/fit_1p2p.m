function [fit, metric, info] = fit_1p2p(tr1, tr2, fps)
% Inputs:
%   - tr1: z-scored 1P trace
%   - tr2: z-scored 2P trace

% Parameters
info.params.order = 2;
info.params.activity_threshold = 3; % sigma
info.params.activity_period_padding = 0.5; % seconds
info.params.x_slope = 1/3*max(tr2); % Evaluate slope at 33.3% of the dynamic range
info.params.residual_percentile = 95;

% We fit the "active periods" in the 1P and 2P traces. In other words,
% we'll ignore the periods during which both 1P and 2P traces are quiet,
% which don't yield insight whether the 1P and 2P cells match.
activity_threshold = info.params.activity_threshold;
activity_period_padding = info.params.activity_period_padding;

binary_trace = (tr1 > activity_threshold) | (tr2 > activity_threshold);
binary_trace = medfilt1(single(binary_trace), 3); % Eliminate isolated "active' frames

[active_segments, num_active_segments] = parse_active_frames(binary_trace,...
    round(activity_period_padding*fps));

mask = false(length(tr1), 1);
if (num_active_segments == 0)
    info.active_segments = [];
    info.active_frames = mask;
    info.num_active_frames = 0;
    
    fit = [];
    metric = [];
else
    active_frames_list = frame_segments_to_list(active_segments);
    mask(active_frames_list) = true;
    num_active_frames = sum(mask);

    p = polyfitZero(tr2(mask), tr1(mask), info.params.order); % Force intercept at origin
%     p = polyfit(tr2(mask), tr1(mask), info.params.order);
    tr1_fit = polyval(p, tr2);

    % "Transfer" curve
    x = linspace(min(tr2), max(tr2));
    y = polyval(p, x);
    
    % Fraction of variance explained (FVE). Note:
    %   - The FVE is computed over the active frames
    %   - When 'polyfitZero' is used, the fve can be negative
    fve = 1 - var(tr1(mask)-tr1_fit(mask))/var(tr1(mask));
    
    % Fraction of frames with a "good" fit. The residual threshold is
    % computed from the baseline of the 1P and 2P traces.
    residuals = abs(tr1 - tr1_fit);
    residual_threshold = prctile(residuals(~mask), info.params.residual_percentile);
    
    num_good_frames = sum(residuals(mask) < residual_threshold);
    fraction_good_fit = num_good_frames / num_active_frames;
    
    % Evaluate slope of fit
    pd = polyder(p);
    slope = polyval(pd, info.params.x_slope);

    % Package for output
    %------------------------------------------------------------
    info.active_segments = active_segments;
    info.active_frames = mask;
    info.num_active_frames = num_active_frames;
    
    fit.tr1 = tr1_fit;
    fit.residuals = residuals;
    fit.x = x;
    fit.y = y;
    fit.slope = slope;
       
    metric.fraction_variance_explained = fve;
    metric.residual_threshold = residual_threshold;
    metric.fraction_good_fit = fraction_good_fit;
end