function show_opto(bdata)

eps = 1e-4; % Used for drawing "staircase" traces
opto_shade = [0 0.4470 0.7410 0.25]; % Transparent blue color

% max_time is the time when the apparatus is switched off
max_time = bdata.frame_times(end);

us_times = bdata.us_times;
us_times = [us_times-eps us_times];
us_times = us_times';
us_times = us_times(:);
us_times = [0; us_times; max_time];

num_us = length(bdata.us_times);
us_counts = 0:num_us;
us_counts = kron(us_counts, [1 1])';

opto_periods = bdata.opto_periods;
num_opto_periods = size(opto_periods, 1);

% Resample reward rate aligned to opto onsets and offsets.
t = linspace(-60, 60, 1e3);
Y_onsets = zeros(num_opto_periods, length(t));
Y_offsets = zeros(num_opto_periods, length(t));
for k = 1:num_opto_periods
    op = opto_periods(k,:);
    y = interp1(us_times, us_counts, op(1)+t, 'nearest');
    y0 = interp1(us_times, us_counts, op(1), 'nearest');
    Y_onsets(k,:) = y - y0;
    
    y = interp1(us_times, us_counts, op(2)+t, 'nearest');
    y0 = interp1(us_times, us_counts, op(2), 'nearest');
    Y_offsets(k,:) = y - y0;
end

hf = figure;
set(hf, 'DefaultAxesFontSize', 18);

% Display running rewards over the entire session
subplot(211);
hold on;
for k = 1:num_opto_periods
    op = opto_periods(k,:);
    rectangle('Position', [op(1) 0 op(2)-op(1) num_us+1],...
              'EdgeColor', 'none', 'FaceColor', opto_shade);
end
plot(us_times, us_counts, 'k-');
xlim([0 max_time]);
ylim([0 num_us+1]);
set(gca, 'TickLength', [0 0]);
xlabel('Time (s)');
ylabel('Cumulative rewards');
grid on;
hold off;
title(dirname);

% Rewards aligned to opto onset
subplot(223);
Y_max = max(Y_onsets(:,end))+1;
Y_min = min(Y_onsets(:,1))-1;
rectangle('Position', [0 Y_min 60 Y_max-Y_min],...
    'EdgeColor', 'none', 'FaceColor', opto_shade);
hold on;
for k = 1:num_opto_periods
    plot(t, Y_onsets(k,:), 'Color', 0.75*[1 1 1]);
end
shadedErrorBar(t, mean(Y_onsets), std(Y_onsets)/sqrt(num_opto_periods));
hold off;
xlabel('Time relative to opto onset (s)');
ylabel('Cumulative rewards (mean \pm s.e.m.)');
title('Aligned to opto onset');
grid on;
xlim(t([1 end]));
ylim([Y_min Y_max]);

% Rewards aligned to opto offset
subplot(224);
Y_max = max(Y_offsets(:,end))+1;
Y_min = min(Y_offsets(:,1))-1;
rectangle('Position', [-60 Y_min 60 Y_max-Y_min],...
    'EdgeColor', 'none', 'FaceColor', opto_shade);
hold on;
for k = 1:num_opto_periods
    plot(t, Y_offsets(k,:), 'Color', 0.75*[1 1 1]);
end
shadedErrorBar(t, mean(Y_offsets), std(Y_offsets)/sqrt(num_opto_periods));
hold off;
xlabel('Time relative to opto offset (s)');
ylabel('Cumulative rewards (mean \pm s.e.m.)');
title('Aligned to opto offset');
grid on;
xlim(t([1 end]));
ylim([Y_min Y_max]);