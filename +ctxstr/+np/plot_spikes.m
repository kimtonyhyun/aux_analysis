function plot_spikes(unit_inds, spikes, bdata, sdata)
% bdata = load('ctxstr.mat');
% sdata = load('skeleton.mat');

rec_duration = bdata.info.onebox.time_window(2);
bin_width = 0.25; % s
t = 0:bin_width:rec_duration;

vel = bdata.behavior.velocity;
pos = cell2mat(bdata.behavior.position.by_trial);
us_times = bdata.behavior.us_times;

% Plot
if ~exist('sdata', 'var')
    sdata = [];
    num_rows = 3;
else
    num_rows = 4;
end
axes = zeros(num_rows, 1);

axes(1) = subplot(num_rows, 1, 1); cla;
hold on;
axes(2) = subplot(num_rows, 1, 2); cla;
hold on;

spikeamp_lims = [Inf, -Inf];
fr_lims = [Inf, -Inf];

num_inds = length(unit_inds);
legend_labels = cell(num_inds,1);
for k = 1:num_inds
    unit_ind = unit_inds(k);
    si_unit_id = spikes.orig_unit_ids(unit_ind);
    spikes_k = spikes.spike_data{unit_ind};
    firing_rate = ctxstr.np.compute_firing_rate(spikes_k, t);
    
    num_spikes = length(spikes_k);
    avg_firing_rate = num_spikes / rec_duration;
       
    color = get_color(k);
    legend_labels{k} = sprintf('SI unit %d (%d spikes; %.2f Hz)',...
        si_unit_id, num_spikes, avg_firing_rate);
    
    subplot(axes(1));
    y_lims = tight_plot(spikes_k(:,1), spikes_k(:,2), '.', 'Color', color);
    spikeamp_lims = adjust_ylims(spikeamp_lims, y_lims);
    
    subplot(axes(2));
    y_lims = tight_plot(t, firing_rate, 'Color', color);
    fr_lims = adjust_ylims(fr_lims, y_lims);
end

subplot(axes(1));
plot_vertical_lines(us_times, spikeamp_lims, 'b:');
ylim(spikeamp_lims);
hold off;
ylabel('Spike amplitude (uV)');
legend(legend_labels, 'Location', 'SouthWest');
title(strrep(dirname, '_', '\_'));

subplot(axes(2));
plot_vertical_lines(us_times, fr_lims, 'b:');
ylim(fr_lims);
hold off;
ylabel(sprintf('# spikes per %.2f s bin', bin_width));
% legend(legend_labels, 'Location', 'NorthWest');

axes(3) = subplot(num_rows, 1, 3);
yyaxis left;
v_lims = tight_plot(vel(:,1), vel(:,2));
hold on;
plot_vertical_lines(us_times, v_lims, 'b:');
hold off;
ylabel('Velocity (cm/s)');
yyaxis right;
tight_plot(pos(:,1), pos(:,2));
ylabel('Position (encoder units)');

if ~isempty(sdata)
    axes(4) = subplot(num_rows, 1, 4);
    
    y_lims = [0 180];
    yyaxis left;
    tight_plot(sdata.t, sdata.beta_f);
    hold on;
    plot([0 rec_duration], 90*[1 1], 'k--');
    plot_vertical_lines(us_times, y_lims, 'b:');
    hold off;
    ylim(y_lims);
    set(gca, 'YTick', [0 45 90 135 180]);
    ylabel('Front limb angle, \beta_f (degrees)');
    
    yyaxis right;
    tight_plot(sdata.t, sdata.beta_h);
    ylim(y_lims);
    set(gca, 'YTick', [0 45 90 135 180]);
    ylabel('Hind limb angle, \beta_h (degrees)');
end

xlabel('Time (s)'); % x-label on bottom subplot

% Overall formatting
set(axes, 'TickLength', [0 0]);
linkaxes(axes, 'x');
zoom xon;

end

function color = get_color(i)

colors = 'ckbrm';
num_colors = length(colors);
color = colors(mod(i, num_colors)+1);

end

function y_lims = adjust_ylims(y_lims, new_y_lims)

if new_y_lims(1) < y_lims(1)
    y_lims(1) = new_y_lims(1);
end

if new_y_lims(2) > y_lims(2)
    y_lims(2) = new_y_lims(2);
end

end