function plot_spikes(k, spikes, bdata)

spikes_k = spikes.spike_data{k};
num_spikes = length(spikes_k);
si_unit_id = spikes.orig_unit_ids(k); % Unit ID as assigned by SpikeInterface

rec_duration = bdata.info.onebox.time_window(2);
avg_firing_rate = num_spikes / rec_duration;

vel = bdata.behavior.velocity;
pos = cell2mat(bdata.behavior.position.by_trial);
us_times = bdata.behavior.us_times;

% Plot
num_rows = 2;
axes = zeros(num_rows, 1);

axes(1) = subplot(num_rows, 1, 1);
spikeamp_lims = tight_plot(spikes_k(:,1), spikes_k(:,2), 'k.');
hold on;
plot_vertical_lines(us_times, spikeamp_lims, 'b:');
hold off;
ylabel('Spike amplitude (uV)');
title_str = sprintf('%s: Orig unit id %d (%d spikes; %.1f Hz avg)',...
    dirname, si_unit_id, num_spikes, avg_firing_rate);
title(strrep(title_str, '_', '\_'));

axes(2) = subplot(num_rows, 1, 2);
yyaxis left;
v_lims = tight_plot(vel(:,1), vel(:,2));
hold on;
plot_vertical_lines(us_times, v_lims, 'b:');
hold off;
ylabel('Velocity (cm/s)');
yyaxis right;
tight_plot(pos(:,1), pos(:,2));
xlabel('Time (s)');
ylabel('Position (encoder units)');

% Formatting
set(axes, 'TickLength', [0 0]);
linkaxes(axes, 'x');
zoom xon;
