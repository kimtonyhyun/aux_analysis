% Show velocities across days
% FIXME: Clean up...
close all;

Vs = {V1, V2, V3, V4, V5, V6, V7, V8};

num_days = length(Vs);
colors = summer(num_days+2);
colors = flipud(colors(1:num_days,:));

for k = 1:num_days
    V = Vs{k};
    color = colors(k,:);
    shadedErrorBar(t0, mean(V), std(V)/sqrt(size(V,1)),...
        {'Color', color}, 1);
    hold on;
end
hold off;
xlim([t0(1) t0(end)]);
grid on;
xlabel('Time relative to reward (s)');
ylabel('Velocity (mean\pms.e.m.; cm/s)');
title(sprintf('%s\nCorrect trials only\nDarker colors later in training', dirname));
set(gca, 'FontSize', 16);