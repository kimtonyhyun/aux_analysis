function show_aligned_raster(cell_idx, trials_to_show, trials, imdata)

% Defaults
font_size = 18;
pre_us_tr_color = 0.5 * [1 1 1];
post_us_tr_color = 0.9 * [1 1 1];
resp_ind_width = 0.25; % Size, in seconds, of the response indicator

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

[R_us, t_us, info_us] = ctxstr.core.compute_us_aligned_raster(cell_idx, trials_to_show, trials, imdata);
[R_mo, t_mo, info_mo] = ctxstr.core.compute_mo_aligned_raster(cell_idx, trials_to_show, trials, imdata);

% US-aligned raster
%------------------------------------------------------------
ax1 = sp(3,2,[1 3]);
plot_transparent_raster(t_us, R_us);
hold on;
mo_color = 'w';
for trial_idx = info_us.trial_inds
    trial = trials(trial_idx);
    
    % Indicate motion onset times
    mo_times = trial.motion.onsets;
    if ~isempty(mo_times)
        mo_times = mo_times - trial.us_time;
        plot(mo_times, trial_idx*ones(size(mo_times)), '.', 'Color', mo_color);
        switch mo_color % Toggle colors
            case 'w'
                mo_color = 'r';
            otherwise
                mo_color = 'w';
        end
    end
    
    % Indicate US and first lick after US
    plot(0, trial_idx, 'cx');
    first_lick_ind = find(trial.lick_times > trial.us_time, 1);
    if ~isempty(first_lick_ind)
        first_lick_time = trial.lick_times(first_lick_ind);
        plot(first_lick_time - trial.us_time, trial_idx, 'k.');
    end
    
    % Did the mouse lick within the response window?
    if trial.lick_response
        resp_color = 'g';
    else
        resp_color = 'r';
    end
    rectangle('Position', [t_us(end) trial_idx-0.5 resp_ind_width 1],...
        'FaceColor', resp_color, 'EdgeColor', 'none');
end
hold off;
set(ax1, 'TickLength', [0 0]);
set(ax1, 'FontSize', font_size);
ylabel('Trial index');

% US-aligned traces
%------------------------------------------------------------
ax2 = sp(3,2,5);
cla;
hold on;
for trial_idx = info_us.trial_inds
    t = info_us.trial_times{trial_idx};
    tr = info_us.traces{trial_idx};

    pre_us = t < 0;
    plot(t(pre_us), tr(pre_us), '-', 'Color', pre_us_tr_color);
    plot(t(~pre_us), tr(~pre_us), '-', 'Color', post_us_tr_color);
end
hold off;
xlabel('Time relative to US (s)');
ylabel('Activity');
ylim([0 1]);
set(ax2, 'TickLength', [0 0]);
set(ax2, 'FontSize', font_size);

% MO-aligned raster
%------------------------------------------------------------
ax3 = sp(3,2,[2 4]);
plot_transparent_raster(t_mo, R_mo);
hold on;
mo_color = 'w';
for trial_idx = info_mo.trial_inds
    trial = trials(trial_idx);
    
    mo_times = trial.motion.onsets;
    if ~isempty(mo_times)
        first_mo_time = mo_times(1);
        mo_times = mo_times - first_mo_time;
        plot(mo_times, trial_idx*ones(size(mo_times)), '.', 'Color', mo_color);
        switch mo_color
            case 'w'
                mo_color = 'r';
            otherwise
                mo_color = 'w';
        end
        plot(trial.us_time - first_mo_time, trial_idx, 'cx');
    end
end
hold off;
set(ax3, 'TickLength', [0 0]);
set(ax3, 'FontSize', font_size);
title('Aligned to first MO of each trial');

% MO-aligned traces
%------------------------------------------------------------
ax4 = sp(3,2,6);
cla;
hold on;
for trial_idx = info_mo.trial_inds
    if ~isempty(info_mo.trial_times{trial_idx})
        trial = trials(trial_idx);
        us_time = trial.us_time - trial.motion.onsets(1);
        
        t = info_mo.trial_times{trial_idx};
        tr = info_mo.traces{trial_idx};
        
        pre_us = t < us_time;
        plot(t(pre_us), tr(pre_us), '-', 'Color', pre_us_tr_color);
        plot(t(~pre_us), tr(~pre_us), '-', 'Color', post_us_tr_color);
    end
end
hold off;
xlabel('Time relative to motion onset (s)');
ylim([0 1]);
set(ax4, 'TickLength', [0 0]);
set(ax4, 'FontSize', font_size);

linkaxes([ax1 ax2], 'x');
linkaxes([ax3 ax4], 'x');
% Important that the two columns share the same range of displayed time, in
% order to allow for qualitative visual comparisons
xlim(ax1, [-8 1+resp_ind_width]);
xlim(ax3, [-3 6+resp_ind_width]);
subplot(ax1);

end

function plot_transparent_raster(t, R)
    alpha = ones(size(R));
    alpha(isnan(R)) = 0;
    imagesc(t, 1:size(R,1), R, 'AlphaData', alpha);
end % plot_transparent_raster
