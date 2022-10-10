function show_aligned_binned_raster(trials_to_show, trials, trace, t)

% Defaults
font_size = 18;
resp_ind_width = 0.25; % Size, in seconds, of the response indicator

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

[R_us, t_us, info_us] = ctxstr.core.compute_us_aligned_raster(trials_to_show, trials, trace, t);
[R_mo, t_mo, info_mo] = ctxstr.core.compute_mo_aligned_raster(trials_to_show, trials, trace, t);

% US-aligned raster
%------------------------------------------------------------
ax1 = sp(4,2,[1 3]);
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
ylabel('Trial index');

% US-aligned traces
%------------------------------------------------------------
num_trials = length(trials_to_show);
min_trial_frac = 0.1;
threshold_num_trials = min_trial_frac * num_trials;
faint_color = 0.6*[1 1 1];

S_us = sum(R_us, 1, 'omitnan');
N_us = sum(~isnan(R_us),1);
F_us = S_us./N_us;

valid_samples = N_us > threshold_num_trials;
ax2 = sp(4,2,5);
plot(t_us([1 end]), threshold_num_trials*[1 1], 'r--');
hold on;
plot(t_us(valid_samples), N_us(valid_samples), 'k.-');
plot(t_us(~valid_samples), N_us(~valid_samples), '.', 'Color', faint_color);
hold off;
grid on;
ylabel('# valid trials');
legend(sprintf('%.0f%% threshold', 100*min_trial_frac), 'Location', 'NorthWest');
ylim([0 1.1*num_trials]);

ax3 = sp(4,2,7);
plot(t_us(valid_samples), 100*F_us(valid_samples), 'k.-');
hold on;
plot(t_us(~valid_samples), 100*F_us(~valid_samples), '.', 'Color', faint_color);
hold off;
grid on;
xlabel('Time relative to US (s)');
ylabel('% of trials with activity');
ylim([0 100]);

% MO-aligned raster
%------------------------------------------------------------
ax4 = sp(4,2,[2 4]);
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
title('Aligned to first MO of each trial');

% MO-aligned traces
%------------------------------------------------------------
S_mo = sum(R_mo, 1, 'omitnan');
N_mo = sum(~isnan(R_mo),1);
F_mo = S_mo ./ N_mo;

valid_samples = N_mo > threshold_num_trials;

ax5 = sp(4,2,6);
plot(t_mo(valid_samples), N_mo(valid_samples), 'k.-');
hold on;
plot(t_mo([1 end]), threshold_num_trials*[1 1], 'r--');
plot(t_mo(~valid_samples), N_mo(~valid_samples), '.', 'Color', faint_color);
hold off;
grid on;
ylim([0 1.1*num_trials]);

ax6 = sp(4,2,8);
plot(t_mo(valid_samples), 100*F_mo(valid_samples), 'k.-');
hold on;
plot(t_mo(~valid_samples), 100*F_mo(~valid_samples), '.', 'Color', faint_color);
hold off;
grid on;
xlabel('Time relative to motion onset (s)');
ylim([0 100]);

% Formatting
set([ax3 ax6], 'YTick', 0:20:100);

set([ax1 ax2 ax3 ax4 ax5 ax6], 'TickLength', [0 0]);
set([ax1 ax2 ax3 ax4 ax5 ax6], 'FontSize', font_size);

linkaxes([ax1 ax2 ax3], 'x');
linkaxes([ax4 ax5 ax6], 'x');
% Important that the two columns share the same range of displayed time, in
% order to allow for qualitative visual comparisons
xlim(ax1, [-8 1+resp_ind_width]);
xlim(ax4, [-3 6+resp_ind_width]);
subplot(ax1);

end

function plot_transparent_raster(t, R)
    alpha = ones(size(R));
    alpha(isnan(R)) = 0;
    imagesc(t, 1:size(R,1), R, 'AlphaData', alpha, [0 1]);
end % plot_transparent_raster
