function [t, axes] = plot_oephys(Vm, Vmfd, dte, iSpk, f_cell, f_np, dto, iFrames2)

te = dte * (0:length(Vm)-1) * 1000; % ms
te_fd = te(1:length(Vmfd));
to = te(iFrames2); % ms
t_range = te([1 end]);

% Show fluorescence trace from cell and neuropil
ax1 = subplot(311);
plot(to, f_cell, 'b');
hold on;
plot(to, f_np, 'c');
hold off;
ylabel(sprintf('Fluorescence\nFrame rate: %.1f Hz', 1/dto));
legend('Cell', 'Neuropil', 'Location', 'Northwest');
xlim(t_range);
ax1.XAxis.Exponent = 0;

ax2 = subplot(312);
plot(te, Vm, 'r');
hold on;
plot(te_fd, Vmfd, 'm--');
plot(te(iSpk), Vmfd(iSpk), 'k.', 'MarkerSize', 6);
hold off;
ylabel(sprintf('Voltage\nSample rate: %.1f Hz', 1/dte));
legend('Raw', 'Filtered', 'Spikes', 'Location', 'Northwest');
ax2.XAxis.Exponent = 0;

% Align imaging and ephys
ax3 = subplot(313);
yyaxis left;
plot(to, f_cell, 'b');
ylabel('Fluorescence');
yyaxis right;
plot(te_fd, Vmfd, 'm');
ylabel('Filtered Vm');
xlabel('Time (ms)');
ax3.XAxis.Exponent = 0;

linkaxes([ax1 ax2 ax3], 'x');
xlim(t_range);

% Package for output
axes = [ax1 ax2 ax3];
t.ephys = te;
t.ephys_fd = te_fd;
t.opt = to;
