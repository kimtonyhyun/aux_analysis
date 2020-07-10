function axes = plot_oephys(t, Vm, Vmfd, iSpk, f_cell, f_np)

t_range = t.ephys([1 end]);
dte = t.ephys(2) - t.ephys(1);
dto = t.opt(2) - t.opt(1);

% Show fluorescence trace from cell and neuropil
ax1 = subplot(311);
plot(t.opt, f_cell, 'b');
hold on;
plot(t.opt, f_np, 'c');
hold off;
ylabel(sprintf('Fluorescence\nFrame rate: %.1f Hz', 1/dto));
legend('Cell', 'Neuropil', 'Location', 'Northwest');
xlim(t_range);
ylim([0 1.1*max(f_cell)]);
ax1.XAxis.Exponent = 0;

ax2 = subplot(312);
plot(t.ephys, Vm, 'r');
hold on;
plot(t.ephys_fd, Vmfd, 'm--');
plot(t.spikes, Vmfd(iSpk), 'k.', 'MarkerSize', 6);
hold off;
ylabel(sprintf('Voltage\nSample rate: %.1f Hz', 1/dte));
legend('Raw', 'Filtered', 'Spikes', 'Location', 'Northwest');
ax2.XAxis.Exponent = 0;

% Align imaging and ephys
ax3 = subplot(313);
yyaxis left;
plot(t.opt, f_cell, 'b');
ylabel('Fluorescence');
yyaxis right;
plot(t.ephys_fd, Vmfd, 'm');
ylabel('Filtered Vm');
xlabel('Time (ms)');
ax3.XAxis.Exponent = 0;

axes = [ax1 ax2 ax3];
linkaxes(axes, 'x');
xlim(t_range);
