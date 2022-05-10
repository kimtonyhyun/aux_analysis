clear;

idx = 36;

ephys_filename = sprintf('AD0_%d', idx);
edata = load(ephys_filename);

etrace = edata.(ephys_filename).data;
num_samples = length(etrace);

t = 0.1 * (0:num_samples-1); % ms
t = t * 1e-3; % s

plot(t, etrace);
xlabel('Time (s)');
ylabel('Ephys (mV)');
grid on;
title(sprintf('%s (%.1f s)', ephys_filename, t(end)),...
        'Interpreter', 'none');
zoom xon;