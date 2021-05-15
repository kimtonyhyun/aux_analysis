function metric = show_1p2p(ds1, idx1, ds2, idx2, tform, fps)
% Adapted from 'show_corr'. Inputs:
%   - ds1: DaySummary of 1P data
%   - ds2: DaySummary of 2P data

% Get data
tr1 = ds1.get_trace(idx1, 'zsc')'; % Column vector
tr2 = ds2.get_trace(idx2, 'zsc')';
num_frames = length(tr1);

min_tr_val = min([min(tr1) min(tr2)]);
max_tr_val = max([max(tr1) max(tr2)]);
tr_lims = [min_tr_val max_tr_val];
tr_lims = tr_lims + 1/10*diff(tr_lims)*[-1 1];

% Perform fit
[fit, metric, info] = fit_1p2p(tr1, tr2, fps);

active_segments = info.active_segments;
mask = info.active_frames;
num_fit_frames = info.num_active_frames;

residuals = fit.residuals;
res_lims = [-0.5 1.1*max(residuals)];

residual_threshold = metric.residual_threshold;

% Display the results of 'fit_1p2p'
%------------------------------------------------------------
color1 = [0 0.4470 0.7410];
color2 = [0.85 0.325 0.098];
gray = 0.75*[1 1 1];
dark_green = rgb('DarkGreen');

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

% Show cell map
%------------------------------------------------------------
sp(2,2,1); % Cellmap overlay

zoom_com = transformPointsForward(tform, ds2.cells(idx2).com')';

% For performance reasons, only show boundaries in the vicinity of
% the cell under consideration
plot_boundaries(ds1, 'Color', color1, 'LineWidth', 2, 'Fill', idx1, 'display_center', zoom_com);
hold on;
plot_boundaries(ds2, 'Color', color2, 'LineWidth', 1, 'Fill', idx2, 'Transform', tform, 'display_center', zoom_com);
xlabel('x (px)');
ylabel('y (px)');
xlim(zoom_com(1) + [-50 50]);
ylim(zoom_com(2) + [-50 50]);
title(sprintf('2P cell idx = %d (red)\n1P cell idx = %d (blue)', idx2, idx1));

% Show trace correlation
%------------------------------------------------------------
corr_sp = sp(2,2,2); % Correlation plot

plot(fit.x, fit.y, 'Color', dark_green);
hold on;
% Black dots indicate points that are used for fitting. Gray dots
% are ignored.
plot(tr2(~mask), tr1(~mask), '.', 'Color', gray);
plot(tr2(mask), tr1(mask), '.k');
hold off;

set(corr_sp, 'XTick', 0:5:max(tr2));
set(corr_sp, 'YTick', 0:5:max(tr1));
grid on;
axis equal tight;
xlabel('2P (\sigma)');
ylabel('1P (\sigma)');
title(sprintf('Variance explained = %.1f%%', 100*metric.fraction_variance_explained));
legend(sprintf('Slope = %.3f', fit.slope), 'Location', 'NorthWest');

% Show traces
%------------------------------------------------------------

% Raw data
ax1 = sp(6,1,4);
hold on;
draw_active_frames(active_segments, tr_lims);
plot(tr1, 'Color', color1);
plot(tr2, 'Color', color2);
plot([1 num_frames], info.params.activity_threshold*[1 1], 'k--');
hold off;
legend({'1P', '2P'}, 'Location', 'NorthWest');
title(sprintf('Number of fitted frames = %d (%.1f%% of all frames)',...
      num_fit_frames, 100*num_fit_frames/num_frames));
xlabel('Frames');
ylabel('Raw data (\sigma)');
set(ax1, 'TickLength', [0 0]);

% Fit to 1P data
ax2 = sp(6,1,5);
hold on;
draw_active_frames(active_segments, tr_lims);
plot(tr1, 'Color', color1);
plot(fit.tr1, 'Color', color2);
legend({'1P (raw data)', '1P fit (from 2P)'}, 'Location', 'NorthWest');
hold off;
ylabel('Fit (\sigma)');
set(ax2, 'TickLength', [0 0]);

linkaxes([ax1 ax2], 'xy');
ylim(tr_lims);

% Residuals
ax3 = sp(6,1,6);
hold on;
res_curve = plot([1 num_frames], residual_threshold*[1 1], 'k--');

draw_active_frames(active_segments, res_lims);

% First, draw residuals of non-fitted frames in gray
plot(find(~mask), residuals(~mask), '.', 'Color', gray);

% Next, color the residuals of fitted frames depending on whether the
% residual exceeds the threshold or not
good_frames = (residuals <= residual_threshold) & mask;
bad_frames = (residuals > residual_threshold) & mask;
plot(find(good_frames), residuals(good_frames), '.', 'Color', dark_green);
plot(find(bad_frames), residuals(bad_frames), 'r.');

hold off;
set(ax3, 'TickLength', [0 0]);
ylabel('Residual (\sigma)');
title(sprintf('Fraction of frames with good fit = %.1f%%', 100*metric.fraction_good_fit));
legend(sprintf('Residual threshold = %.3f', residual_threshold), 'Location', 'NorthWest');
uistack(res_curve, 'top');

linkaxes([ax2 ax3], 'x');
xlim([1 length(tr1)]);
ylim(res_lims);
zoom xon;

end % show_1p2p

function draw_active_frames(active_frames, y_lims)

cyan_transparent = [0 1 1 0.15];

for k = 1:size(active_frames,1)
    af = active_frames(k,:);
    rectangle('Position', [af(1) y_lims(1) af(2)-af(1) y_lims(2)-y_lims(1)],...
        'EdgeColor', 'none',...
        'FaceColor', cyan_transparent);
end

end % draw_active_periods