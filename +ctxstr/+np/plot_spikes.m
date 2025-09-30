function plot_spikes(unit_inds, spikes, bdata)

rec_duration = bdata.info.onebox.time_window(2);

vel = bdata.behavior.velocity;
pos = cell2mat(bdata.behavior.position.by_trial);
us_times = bdata.behavior.us_times;

% Plot
num_rows = 2;
axes = zeros(num_rows, 1);

axes(1) = subplot(num_rows, 1, 1); cla;
hold on;

spikeamp_lims = [Inf, -Inf];
colors = 'ckbrm';
num_colors = length(colors);

num_inds = length(unit_inds);
legend_labels = cell(num_inds,1);
for k = 1:num_inds
    unit_ind = unit_inds(k);
    si_unit_id = spikes.orig_unit_ids(unit_ind);
    spikes_k = spikes.spike_data{unit_ind};
    
    num_spikes = length(spikes_k);
    avg_firing_rate = num_spikes / rec_duration;
       
    color = colors(mod(k, num_colors)+1);
    legend_labels{k} = sprintf('SI unit %d (%d spikes; %.2f Hz)',...
        si_unit_id, num_spikes, avg_firing_rate);
    
    y_lims = tight_plot(spikes_k(:,1), spikes_k(:,2), '.', 'Color', color);
    if y_lims(1) < spikeamp_lims(1)
        spikeamp_lims(1) = y_lims(1);
    end
    if y_lims(2) > spikeamp_lims(2)
        spikeamp_lims(2) = y_lims(2);
    end
end
plot_vertical_lines(us_times, spikeamp_lims, 'b:');
ylim(spikeamp_lims);
hold off;
ylabel('Spike amplitude (uV)');
title(strrep(dirname, '_', '\_'));
legend(legend_labels, 'Location', 'SouthWest');

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
