idx = 12;

ephys_trace = info.ephys_traces{idx};
num_ephys_samples = length(ephys_trace);
t_ephys = 1e-4 * (0:num_ephys_samples-1); % s; ephys sampled at 10 kHz
t_lims = t_ephys([1 end]);

im_trace = traces(:,idx); % dff
num_frames = length(im_trace);
fps = 15.625; % From y-mirror scan waveform measurement
t_im = 1/fps * (0:num_frames-1); % s
% t_im = t_im + t_im(2) * 4; % Account for delay between ephys and imaging

% Based on "shutter experiments", think that imaging frame #157, line #25
% corresponds to t = 10 s in ephys time
t0 = interp1(1:num_frames, t_im, 157.39);
t_im = (t_im - t0) + 10;

cascade_trace = info.fps * spike_probs(:,idx); % spike rate

clf;

ax1 = subplot(311);
yyaxis left;
plot(t_im, im_trace, '.-');
hold on;
% plot(t_im(157), im_trace(157), 'o'); % Frame 157 corresponds to t_ephys = 10 s
ylabel('Imaging (\DeltaF/F)');
yyaxis right;
plot(t_ephys, ephys_trace);
ylabel('Ephys (mV)');
xlim(t_lims);
xlabel('Time (s)');
grid on;
title(sprintf('%s / %s', info.im_filenames{idx}, info.ephys_filenames{idx}),...
    'Interpreter', 'none');

ax2 = subplot(312);
yyaxis left;
plot(t_im, im_trace, '.-');
ylabel('Imaging (\DeltaF/F)');
yyaxis right;
plot(t_im, cascade_trace, 'k.-');
ylabel({'Cascade spike rate (Hz)', model_name}, 'Interpreter', 'none');
ax2.YAxis(2).Color = 'k';
xlim(t_lims);
xlabel('Time (s)');
grid on;

ax3 = subplot(313);
yyaxis left;
plot(t_im, cascade_trace, 'k.-');
ylabel({'Cascade spike rate (Hz)', model_name}, 'Interpreter', 'none');
ax3.YAxis(1).Color = 'k';
yyaxis right;
plot(t_ephys, ephys_trace);
ylabel('Ephys (mV)');
xlabel('Time (s)');
grid on;

linkaxes([ax1 ax2 ax3], 'x');
zoom xon;