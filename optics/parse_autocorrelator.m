close all; clear all;

% Reads in autocorrelator data (analog X/Y acquisition via Saleae)
% and computes pulse FWHM
data = csvread('autocorrelator.csv',1,0); % Skip header

times = data(:,1);
xs = data(:,2);
ys = data(:,3);

%%

subplot(211);
plot(xs); hold on;
plot(ys,'r'); hold off;
xlabel('Sample');
ylabel('Voltage');
grid on;
xlim([1 length(times)]);
ylim([-0.5 5.5]);
title('Raw autocorrelator recording');
% legend('X','Y', 'Location', 'NorthWest');

%%

% Input required: Identify the start/end of a single scan
scan_start = 3.31e5;
scan_end = 5.643e5;

x = xs(scan_start:scan_end);
x = flipud(x); % By default, scan proceeds from higher to lower delay
x = 2000/5*x; % Convert to delay (fs): 2000 fs <==> 5 V
y = ys(scan_start:scan_end);
y = flipud(y); % Match the flipping of x
y = y - min(y); % Subtract baseline

y_max = max(y);

subplot(212);
plot(x,y); hold on;
plot([0 2000], y_max*[1 1], 'b--');
plot([0 2000], y_max/2*[1 1], 'b--');
hold off;
xlim([0 2000]);
xlabel('Delay (fs)');
ylabel('Autocorrelator (V; baseline-subtracted)');
grid on;

% Compute the FWHM of autocorrelator function (acf)
s_lower = find(y>y_max/2, 1, 'first');
s_upper = find(y>y_max/2, 1, 'last');
fwhm_acf = x(s_upper) - x(s_lower);
fwhm_pulse = fwhm_acf / 1.54; % Assuming sech^2 pulse

title(sprintf('FWHM_{ACF}=%.0f fs; FWHM_{SECH^2}=%.0f fs',...
    fwhm_acf, fwhm_pulse));