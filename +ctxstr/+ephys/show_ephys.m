clear;

idx = 46;

ephys_filename = sprintf('AD0_%d', idx);
fprintf('* * * Displaying "%s" * * *\n', ephys_filename);
edata = load(ephys_filename);

etrace = edata.(ephys_filename).data;
num_samples = length(etrace);

t = 0.1 * (0:num_samples-1); % ms
t = t * 1e-3; % s

y_lims = tight_plot(t, etrace);
xlabel('Time (s)');
ylabel('Ephys (mV)');
grid on;
title(sprintf('%s (%.1f s)', ephys_filename, t(end)),...
        'Interpreter', 'none');
zoom xon;

h_thresh = [];
h_spike_times = [];

%% Spike detection parameters

min_height = 0;
min_prominence = 5;
min_distance = 30; % # samples at 0.1 ms sampling
[~, spike_samples] = findpeaks(etrace, 'MinPeakHeight', min_height,...
                                       'MinPeakProminence', min_prominence,...
                                       'MinPeakDistance', min_distance);
num_spikes = length(spike_samples);
fprintf('Found %d candidate spike events\n', num_spikes);

% Visualize detected spikes
delete(h_thresh);
delete(h_spike_times);

hold on;
h_thresh = plot(t([1 end]), min_height*[1 1], 'k--');
h_spike_times = plot(t(spike_samples), etrace(spike_samples), 'ro');
hold off;

%% Save spike times

info.num_spikes = num_spikes;
info.findpeaks.min_height = min_height;
info.findpeaks.min_prominence = min_prominence;
info.findpeaks.min_distance = min_distance;

spikes_filename = sprintf('spikes_%03d.mat', idx);
save(spikes_filename, 'spike_samples', 'info');
fprintf('Spikes saved to "%s"\n', spikes_filename);