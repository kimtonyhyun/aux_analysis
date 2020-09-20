clear all; close all;

% Show velocities across days
% Assumes:
%   - Current directory represents a mouse (e.g. "oh17")
%   - Each training day is a subdirectory (e.g. "oh17-0912")

mouse_name = dirname;

datasets = dir(sprintf('%s-*', mouse_name));
num_datasets = length(datasets);

cprintf('blue', 'Found %d datasets for mouse "%s"!\n', num_datasets, mouse_name);

%% Retrieve the velocity data for each dataset

Vs = cell(num_datasets, 1);
for k = 1:num_datasets
    dataset_path = datasets(k).name;
    d = load(fullfile(dataset_path, 'ctxstr.mat'));
    
    % Outputs:
    %   V: Velocity raster
    %   R: Consumed US within 1 s (default)?
    %   t0: Time window for the velocity trace
    [V, R, t0] = show_alignment_to_us(d.behavior);
    
    Vs{k} = V(R,:); % Subsample rewarded trials
end

close all; % 'show_alignment_to_us' generates plots

%% Plot velocity profile

colors = summer(num_datasets+2);
colors = flipud(colors(1:num_datasets,:));

for k = 1:num_datasets
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
title(sprintf('%s\nCorrect trials only\nDarker colors later in training', mouse_name));
set(gca, 'FontSize', 16);