clear;

dataset_name = '220502';
load(get_most_recent_file('.', 'rec_*.mat'));
load(get_most_recent_file('.', 'cascade_*.mat'));

%%

idx = 2;

smoothing = 0.2; % Standard deviation of the Gaussian used by CASCADE to 
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

cascade_trace = fps * spike_probs(:,idx); % spike rate

spike_rate = zeros(size(im_trace));
for k = 1:num_spikes
    spike_time = t_ephys(spike_samples(k));
    spike_rate = spike_rate + ...
        1/fps * normpdf(t_im, spike_time, smoothing)'; % 1/fps scaling per CASCADE
end

clf;

ax1 = subplot(411);
yyaxis left;
plot(t_im, im_trace, '.-');
hold on;
ylabel('Imaging (\DeltaF/F)');
yyaxis right;
plot(t_ephys, ephys_trace);
ylabel('Ephys (mV)');
xlabel('Time (s)');
title(sprintf('%s: %s / %s', dataset_name,...
    info.im_filenames{idx}, info.ephys_filenames{idx}),...
    'Interpreter', 'none');
grid on;

ax2 = subplot(412);
yyaxis left;
plot(t_im, im_trace, '.-');
ylabel('Imaging (\DeltaF/F)');
yyaxis right;
plot(t_im, cascade_trace, 'k.-');
ylabel({'Cascade spike rate (Hz)', model_name}, 'Interpreter', 'none');
ax2.YAxis(2).Color = 'k';
xlabel('Time (s)');
grid on;

ax3 = subplot(413);
ephys_color = [0.85 0.325 0.098];
yyaxis left;
plot(t_ephys, ephys_trace, 'Color', ephys_color);
hold on;
plot(t_ephys(spike_samples), ephys_trace(spike_samples), '.',...
    'Color', ephys_color, 'MarkerSize', 18); % Spike times
hold off;
ylabel('Ephys (mV)');
ax3.YAxis(1).Color = ephys_color;
yyaxis right;
plot(t_im, spike_rate, 'm.-');
ax3.YAxis(2).Color = 'm';
ylabel({'Gaussian-filtered spike rate (Hz)',...
        sprintf('smoothing = %d ms', smoothing * 1e3)});
grid on;

ax4 = subplot(414);
yyaxis left;
plot(t_im, cascade_trace, 'k.-');
ylabel({'Cascade spike rate (Hz)', model_name}, 'Interpreter', 'none');
ax4.YAxis(1).Color = 'k';
yyaxis right;
plot(t_im, spike_rate, 'm.-');
ax4.YAxis(2).Color = 'm';
ylabel({'Gaussian-filtered spike rate (Hz)',...
        sprintf('smoothing = %d ms', smoothing * 1e3)});
xlabel('Time (s)');
grid on;

all_axes = [ax1 ax2 ax3 ax4];
set(all_axes, 'TickLength', [0 0]);
linkaxes(all_axes, 'x');
set(all_axes, 'XLim', t_lims);
zoom xon;

%%

savename = sprintf('%s_recording%03d.png', dataset_name, idx);
print('-dpng', savename);