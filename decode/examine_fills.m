function examine_fills(ds, cell_idx, wn_trials, ws_trials, pos_frames)
% FIXME: Hard-coded for changing path analysis and moreover uses the 'wn'
% and 'ws' nomenclature throughout!

pos_frames = pos_frames + (ds.trial_indices(:,1)-1);

% Precompute data
[wn_raster_tr, wn_info] = ds.get_aligned_trace(cell_idx, wn_trials, pos_frames(wn_trials));
[ws_raster_tr, ws_info] = ds.get_aligned_trace(cell_idx, ws_trials, pos_frames(ws_trials));
wn_raster_c = ds.get_aligned_trace(cell_idx, wn_trials, pos_frames(wn_trials), 'fill', 'copy');
ws_raster_c = ds.get_aligned_trace(cell_idx, ws_trials, pos_frames(ws_trials), 'fill', 'copy');
wn_raster_cz = ds.get_aligned_trace(cell_idx, wn_trials, pos_frames(wn_trials), 'fill', 'copyzero');
ws_raster_cz = ds.get_aligned_trace(cell_idx, ws_trials, pos_frames(ws_trials), 'fill', 'copyzero');

% Alignment frame index
wn0 = find(wn_info.aligned_time==0);
ws0 = find(ws_info.aligned_time==0);

% Display parameters
x_range = [min([wn_info.aligned_time(1), ws_info.aligned_time(1)])...
           max([wn_info.aligned_time(end), ws_info.aligned_time(end)])];
y_range = ds.trace_range(cell_idx,:);

% 'traces' fill
%------------------------------------------------------------
h_wn_tr = subplot(3,5,1);
plot_raster(wn_info, wn_raster_tr, y_range);
colormap parula;
ylabel(sprintf('West-north trials (%d)', wn_info.num_trials));
title('traces');

h_ws_tr = subplot(3,5,6);
plot_raster(ws_info, ws_raster_tr, y_range);
ylabel(sprintf('West-south trials (%d)', ws_info.num_trials));

subplot(3,5,11);
% plot_averages(wn_info.aligned_time, wn_raster_tr,...
%               ws_info.aligned_time, ws_raster_tr);
plot_conditions(wn_info, wn_raster_tr(:,wn0), ws_info, ws_raster_tr(:,ws0), y_range);

% 'copy' fill
%------------------------------------------------------------
h_wn_c = subplot(3,5,2);
plot_raster(wn_info, wn_raster_c, y_range);
title('copy');

h_ws_c = subplot(3,5,7);
plot_raster(ws_info, ws_raster_c, y_range);

subplot(3,5,12);
% plot_averages(wn_info.aligned_time, wn_raster_c,...
%               ws_info.aligned_time, ws_raster_c);
plot_conditions(wn_info, wn_raster_c(:,wn0), ws_info, ws_raster_c(:,ws0), y_range);

% 'copyzero' fill
%------------------------------------------------------------
h_wn_cz = subplot(3,5,3);
plot_raster(wn_info, wn_raster_cz, y_range);
title('copyzero');

h_ws_cz = subplot(3,5,8);
plot_raster(ws_info, ws_raster_cz, y_range);

subplot(3,5,13);
% plot_averages(wn_info.aligned_time, wn_raster_cz,...
%               ws_info.aligned_time, ws_raster_cz);
plot_conditions(wn_info, wn_raster_cz(:,wn0), ws_info, ws_raster_cz(:,ws0), y_range);

% Compare values at the alignment frame
%------------------------------------------------------------
subplot(3,5,[4 5]);
plot_fills(wn_info, wn_raster_tr(:,wn0), wn_raster_c(:,wn0), wn_raster_cz(:,wn0), y_range);
title('traces (blue); copy (red); copyzero (magenta)');
subplot(3,5,[9 10]);
plot_fills(ws_info, ws_raster_tr(:,ws0), ws_raster_c(:,ws0), ws_raster_cz(:,ws0), y_range);

% Misc
linkaxes([h_wn_tr h_wn_c h_wn_cz], 'xy');
linkaxes([h_ws_tr h_ws_c h_ws_cz], 'xy');

end

function plot_raster(info, Y, y_range)
    imagesc(info.aligned_time, 1:info.num_trials, Y, y_range);
    hold on;
    plot([0 0], [1 info.num_trials], 'w--');
    hold off;
    % Label y-axis with real trial indices
    set(gca, 'YTick', 1:info.num_trials,...
             'YTickLabel', num2cell(info.trial_inds),...
             'FontSize', 8);
end

function plot_averages(x1, Y1, x2, Y2)
    shadedErrorBar(x1, mean(Y1), std(Y1), 'b', 1);
    hold on;
    shadedErrorBar(x2, mean(Y2), std(Y2), 'r', 1);
    hold off;
    grid on;
    set(gca, 'YLimSpec', 'tight');
end

function plot_fills(info, samples_tr, samples_c, samples_cz, y_range)
    plot(samples_tr, 'b.-');
    hold on;
    plot(samples_c, 'ro-');
    plot(samples_cz, 'm.-');
    hold off;
%     grid on;
    xlim([1 info.num_trials]);
    set(gca, 'XTick', 1:info.num_trials,...
             'XTickLabel', num2cell(info.trial_inds),...
             'XTickLabelRotation', 90,...
             'FontSize', 8);
    xlabel('Trial index');
    ylabel('Sampled fluorescence at 0');
    ylim(y_range);
end

function plot_conditions(info1, samples1, info2, samples2, y_range)
    stem(info1.trial_inds, samples1, 'b.');
    hold on;
    stem(info2.trial_inds, samples2, 'r.');
    hold off;
    ylim(y_range);
    grid on;
%     ylabel('Sampled fluorescence at 0');
end