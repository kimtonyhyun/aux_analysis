function visualize_step_response(regressor, kernel)

% An easy to interpret input function
fps = 15;
t = 1/fps * (-10*fps:10*fps);
t_on = 0;
t_off = 4;
u = double(t>=t_on & t<=t_off);

subplot(311);
plot(regressor.t_kernel, kernel, '.-');
hold on;
plot(regressor.t_kernel([1 end]), [0 0], 'k--');
hold off;
xlim(regressor.t_kernel([1 end]));
xlabel('Time (s)');
ylabel('Kernel, k[t]');
title(regressor.name);

ax2 = subplot(312);
plot(t, u, '.-');
grid on;
xlabel('Time (s)');
ylabel('Input, u[t]');

ax3 = subplot(313);
U = ctxstr.analysis.regress.generate_temporally_offset_regressors(u,...
        -regressor.j_kernel(1), regressor.j_kernel(end))';
y = U*kernel;
plot(t,y, '.-');
grid on;
xlabel('Time (s)');
ylabel('Output, (u*k)[t]');

linkaxes([ax2 ax3], 'x');
xlim(t([1 end]));
zoom xon;