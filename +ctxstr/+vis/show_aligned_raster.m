function show_aligned_raster(cell_idx, trials_to_show, trials, imdata)

% Defaults
font_size = 18;
color_for_individual_trial = 0.5 * [1 1 1];

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

[R_us, t_us, info_us] = ctxstr.core.compute_us_aligned_raster(cell_idx, trials_to_show, trials, imdata);
[R_mo, t_mo, info_mo] = ctxstr.core.compute_mo_aligned_raster(cell_idx, trials_to_show, trials, imdata);

ax1 = sp(3,2,[1 3]);
plot_transparent_raster(t_us, R_us);
hold on;
mo_color = 'w';
for k = 1:info_us.n
    trial_idx = info_us.orig_trial_inds(k);
    trial = trials(trial_idx);
    
    mo_times = trial.motion.onsets;
    if ~isempty(mo_times)
        mo_times = mo_times - trial.us_time;
        plot(mo_times, k*ones(size(mo_times)), '.', 'Color', mo_color);
        switch mo_color % Toggle colors
            case 'w'
                mo_color = 'r';
            otherwise
                mo_color = 'w';
        end
    end
end
plot([0 0], [0 info_us.n], 'c--'); % Mark US time
hold off;
set(ax1, 'TickLength', [0 0]);
set(ax1, 'FontSize', font_size);
ylabel('Trial index');

ax2 = sp(3,2,5);
cla;
hold on;
for k = 1:info_us.n
    if ~isempty(info_us.trial_times{k})
        plot(info_us.trial_times{k}, info_us.traces{k}, '-', 'Color', color_for_individual_trial);
    end
end
hold off;
xlabel('Time relative to US (s)');
ylabel('Activity');
set(ax2, 'TickLength', [0 0]);
set(ax2, 'FontSize', font_size);

ax3 = sp(3,2,[2 4]);
plot_transparent_raster(t_mo, R_mo);
hold on;
mo_color = 'w';
for k = 1:info_mo.n
    trial_idx = info_mo.orig_trial_inds(k);
    mo_times = trials(trial_idx).motion.onsets;
    if ~isempty(mo_times)
        mo_times = mo_times - mo_times(1); % Time relative to first MO of trial
        plot(mo_times, k*ones(size(mo_times)), '.', 'Color', mo_color);
        switch mo_color
            case 'w'
                mo_color = 'r';
            otherwise
                mo_color = 'w';
        end
    end
end
hold off;
set(ax3, 'TickLength', [0 0]);
set(ax3, 'FontSize', font_size);
title('Aligned to first MO of each trial');

ax4 = sp(3,2,6);
cla;
hold on;
for k = 1:info_mo.n
    plot(info_mo.trial_times{k}, info_mo.traces{k}, '-', 'Color', color_for_individual_trial);
end
hold off;
xlabel('Time relative to motion onset (s)');
set(ax4, 'TickLength', [0 0]);
set(ax4, 'FontSize', font_size);

linkaxes([ax1 ax2], 'x');
linkaxes([ax3 ax4], 'x');
% Important that the two columns share the same range of displayed time, in
% order to allow for qualitative visual comparisons
xlim(ax1, [-8 1]);
xlim(ax3, [-3 6]);
subplot(ax1);

end

function plot_transparent_raster(t, R)
    alpha = ones(size(R));
    alpha(isnan(R)) = 0;
    imagesc(t, 1:size(R,1), R, 'AlphaData', alpha);
end % plot_transparent_raster
