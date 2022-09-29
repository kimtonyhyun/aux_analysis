clear;

dataset_name = dirname(2); % Two directories up
smoothing = 100; % ms
load(get_most_recent_file('.', 'rec_*.mat'));
load(get_most_recent_file('.', sprintf('cascade_*_smoothing%dms.mat', smoothing)));

%%

idx = 1;

ephys_trace = info.ephys_traces{idx};
num_ephys_samples = length(ephys_trace);
t_ephys = 1e-4 * (0:num_ephys_samples-1); % s; ephys sampled at 10 kHz
t_lims = t_ephys([1 end]);

spike_samples = info.spike_samples{idx};
spike_times = t_ephys(spike_samples);
num_spikes = length(spike_times);

im_trace = traces(:,idx); % dff
num_frames = length(im_trace);
fps = info.fps;
t_im = 1/fps * (0:num_frames-1); % s

nu = calculate_noise_level_nu(im_trace, fps);

% Based on "shutter experiments", think that imaging frame #157, line #25
% corresponds to t = 10 s in ephys time
t0 = interp1(1:num_frames, t_im, 157.39);
t_im = (t_im - t0) + 10;

cascade_trace = spike_probs(:,idx);

ground_truth_spike_prob = zeros(size(im_trace));
for k = 1:num_spikes
    ground_truth_spike_prob = ground_truth_spike_prob + ...
        1/fps * normpdf(t_im, spike_times(k), smoothing/1e3)'; % 1/fps scaling per CASCADE
end

% Display results
clf;
ephys_color = [0.85 0.325 0.098];

ax1 = subplot(411);
yyaxis left;
tight_plot(t_im, im_trace, '.-');
hold on;
ylabel('Imaging (\DeltaF/F)');
yyaxis right;
y_lim = tight_plot(t_ephys, ephys_trace);
hold on;
y_spikes = y_lim(1) + 0.95*diff(y_lim);
plot(spike_times, y_spikes*ones(num_spikes,1), '.',...
    'Color', ephys_color, 'MarkerSize', 18); % Spike times
hold off;
ylabel('Ephys (mV)');
xlabel('Time (s)');
title_str = sprintf('%s: %s / %s', dataset_name,...
    info.im_filenames{idx}, info.ephys_filenames{idx});
title(title_str, 'Interpreter', 'none');
grid on;

ax2 = subplot(412);
yyaxis left;
tight_plot(t_im, im_trace, '.-');
ylabel('Imaging (\DeltaF/F)');
yyaxis right;
tight_plot(t_im, cascade_trace, 'k.-');
ylabel({'Inferred spike prob.', model_name}, 'Interpreter', 'none');
ax2.YAxis(2).Color = 'k';
xlabel('Time (s)');
grid on;

ax3 = subplot(413);
yyaxis left;
y_lim1 = tight_plot(t_im, cascade_trace, 'k.-');
ylabel({'Inferred spike prob.', model_name}, 'Interpreter', 'none');
ax3.YAxis(1).Color = 'k';
yyaxis right;
y_lim2 = tight_plot(t_im, ground_truth_spike_prob, 'm.-');
ax3.YAxis(2).Color = 'm';
y_lim = [min([y_lim1(1) y_lim2(1)]) max([y_lim1(2) y_lim2(2)])];
ax3.YAxis(1).Limits = y_lim;
ax3.YAxis(2).Limits = y_lim;
hold on;
y_spikes = y_lim(1) + 0.95*diff(y_lim);
plot(spike_times, y_spikes*ones(num_spikes,1), '.',...
    'Color', ephys_color, 'MarkerSize', 18); % Spike times
hold off;
ylabel({'Ground truth spike prob.',...
        sprintf('smoothing = %d ms', smoothing)});
xlabel('Time (s)');
grid on;

ax4 = subplot(414);
yyaxis left;
tight_plot(t_im, cascade_trace, 'k.-');
ylabel({'Same as above', '(Rescaled)'});
ax4.YAxis(1).Color = 'k';
yyaxis right;
tight_plot(t_im, ground_truth_spike_prob, 'm.-');
hold on;
plot(spike_times, y_spikes*ones(num_spikes,1), '.',...
    'Color', ephys_color, 'MarkerSize', 18); % Spike times
hold off;
ax4.YAxis(2).Color = 'm';
ylabel('Same as above');
xlabel('Time (s)');
grid on;

all_axes = [ax1 ax2 ax3 ax4];
set(all_axes, 'TickLength', [0 0]);
linkaxes(all_axes, 'x');
set(all_axes, 'XLim', t_lims);
zoom xon;

% Prepare for output
xlim([8 24]);

% recording_idx = sscanf(info.ephys_filenames{idx}, 'AD0_%d.mat');
% savename = sprintf('%s_rec%03d_smoothing%d.png',...
%     dataset_name, recording_idx, smoothing);
% print('-dpng', savename);

%%

no_spike_samples = (t_im < 3); % First 3 s of recording

spike_time = 10;
samples_for_dff = (spike_time < t_im) & (t_im < spike_time + 3);
samples_for_sr  = (spike_time - 0.5 < t_im) & (t_im < spike_time + 3);

x1 = [max(im_trace(no_spike_samples)) max(im_trace(samples_for_dff)) max(cascade_trace(samples_for_sr)) max(ground_truth_spike_prob(samples_for_sr))];

spike_time = 15;
samples_for_dff = (spike_time < t_im) & (t_im < spike_time + 3);
samples_for_sr  = (spike_time - 0.5 < t_im) & (t_im < spike_time + 3);

x2 = [NaN max(im_trace(samples_for_dff)) max(cascade_trace(samples_for_sr)) max(ground_truth_spike_prob(samples_for_sr))];

[x1; x2]