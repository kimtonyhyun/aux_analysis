clear;

dataset_name = '220318';
load(get_most_recent_file('.', 'rec_*.mat'));
load(get_most_recent_file('.', 'cascade_*.mat'));

%%

idx = 44;

smoothing = 0.1; % Standard deviation of the Gaussian used by CASCADE to 
                 % smooth the ground truth spike rate.

ephys_trace = info.ephys_traces{idx};
num_ephys_samples = length(ephys_trace);
t_ephys = 1e-4 * (0:num_ephys_samples-1); % s; ephys sampled at 10 kHz
t_lims = t_ephys([1 end]);

spike_samples = info.spike_samples{idx};
num_spikes = length(spike_samples);

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
    spike_time = t_ephys(spike_samples(k));
    ground_truth_spike_prob = ground_truth_spike_prob + ...
        1/fps * normpdf(t_im, spike_time, smoothing)'; % 1/fps scaling per CASCADE
end

clf;

ax1 = subplot(411);
yyaxis left;
tight_plot(t_im, im_trace, '.-');
hold on;
ylabel('Imaging (\DeltaF/F)');
yyaxis right;
tight_plot(t_ephys, ephys_trace);
ylabel('Ephys (mV)');
xlabel('Time (s)');
title(sprintf('%s: %s / %s', dataset_name,...
    info.im_filenames{idx}, info.ephys_filenames{idx}),...
    'Interpreter', 'none');
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
ephys_color = [0.85 0.325 0.098];
yyaxis left;
tight_plot(t_ephys, ephys_trace, 'Color', ephys_color);
hold on;
plot(t_ephys(spike_samples), ephys_trace(spike_samples), '.',...
    'Color', ephys_color, 'MarkerSize', 18); % Spike times
hold off;
ylabel('Ephys (mV)');
ax3.YAxis(1).Color = ephys_color;
yyaxis right;
tight_plot(t_im, ground_truth_spike_prob, 'm.-');
ax3.YAxis(2).Color = 'm';
ylabel({'Ground truth spike prob.',...
        sprintf('smoothing = %d ms', smoothing * 1e3)});
grid on;

ax4 = subplot(414);
yyaxis left;
y_lim1 = tight_plot(t_im, cascade_trace, 'k.-');
ylabel({'Inferred spike prob.', model_name}, 'Interpreter', 'none');
ax4.YAxis(1).Color = 'k';
yyaxis right;
y_lim2 = tight_plot(t_im, ground_truth_spike_prob, 'm.-');
ax4.YAxis(2).Color = 'm';
ylabel({'Ground truth spike prob.',...
        sprintf('smoothing = %d ms', smoothing * 1e3)});
% Plot spike probs on same y-lim
y_lim = [min([y_lim1(1) y_lim2(1)]) max([y_lim1(2) y_lim2(2)])];
ax4.YAxis(1).Limits = y_lim;
ax4.YAxis(2).Limits = y_lim;
xlabel('Time (s)');
grid on;

all_axes = [ax1 ax2 ax3 ax4];
set(all_axes, 'TickLength', [0 0]);
linkaxes(all_axes, 'x');
set(all_axes, 'XLim', t_lims);
zoom xon;

xlim([8 16]);

recording_idx = sscanf(info.ephys_filenames{idx}, 'AD0_%d.mat');
savename = sprintf('%s_recording%03d.png', dataset_name, recording_idx);
print('-dpng', savename);