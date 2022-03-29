clear all; close all;

% Show velocities across days
% Assumes:
%   - Current directory represents a mouse (e.g. "oh17")
%   - Each training day is a subdirectory (e.g. "oh17-0912")

mouse_name = dirname;

% strtok(..., '-') converts names like "oh14-spokes" to just "oh14"
datasets = dir(sprintf('%s-*', strtok(mouse_name, '-')));
datasets(~[datasets.isdir]) = [];
num_datasets = length(datasets);

cprintf('blue', 'Found %d datasets for mouse "%s"!\n', num_datasets, mouse_name);

%% Retrieve behavioral data from each dataset

V_corr = cell(num_datasets, 1);

num_rewards = zeros(num_datasets, 1);
num_rewards_corr = zeros(num_datasets, 1);
IRIs = cell(num_datasets, 1);
IRIs_corr = cell(num_datasets, 1);

for k = 1:num_datasets
    dataset_path = datasets(k).name;
    d = load(fullfile(dataset_path, 'ctxstr.mat'));
    
    % Outputs:
    %   V: Velocity raster
    %   R: Consumed US within 1 s (default)?
    %   t0: Time window for the velocity trace
    [V, R, t0] = ctxstr.behavior.show_alignment_to_us(d.behavior);
    IRI = diff(d.behavior.us_times);    
    
    V_corr{k} = V(R,:); % Correct trials only
    
    num_rewards(k) = length(R);
    num_rewards_corr(k) = sum(R);
    
    IRIs{k} = IRI;
    IRIs_corr{k} = IRI(R(2:end));
end

close all; % 'show_alignment_to_us' generates plots

%% Figure 1: Plot velocity profiles over learning

close all;

colors = summer(num_datasets+2);
colors = flipud(colors(1:num_datasets,:));

for k = 1:num_datasets
    V = V_corr{k};
    color = colors(k,:);
    shadedErrorBar(t0, mean(V), std(V)/sqrt(size(V,1)),...
        'lineProps', {'Color', color, 'LineWidth', 1});
    hold on;
end
hold off;
xlim([t0(1) t0(end)]);
grid on;
xlabel('Time relative to reward (s)');
ylabel('Velocity (mean\pms.e.m.; cm/s)');
title(sprintf('%s\nCorrect trials only\nDarker colors later in training (%d days shown)',...
              mouse_name, num_datasets));
set(gca, 'FontSize', 16);

%% Figure 2: Plot reward stats over learning

close all;

days = (1:num_datasets)';
days_cell = num2cell(days);
max_num_rewards = max(num_rewards);


% Row 1: Num rewards over learning
%------------------------------------------------------------
subplot(3,3,[1 2]);
x_range = [0.5 num_datasets+0.5];

plot(days, num_rewards_corr, 'd-', 'Color', [0 0.5 0], 'MarkerFaceColor', [0 0.5 0], 'MarkerSize', 6);
hold on;
plot(days, num_rewards, 'ko-', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
hold off;
% xlabel('Days in training');
ylabel('Num rewards');
grid on;
title(dirname, 'Interpreter', 'None');
legend('Consumed', 'Total', 'Location', 'NorthWest');
xlim(x_range);
ylim([0 max_num_rewards+10]);

subplot(3,3,3);
plot(days, num_rewards_corr./num_rewards, 'ko-', 'MarkerFaceColor', [0 0.5 0], 'MarkerSize', 6);
grid on;
xlim(x_range);
ylim([0 1.1]);
xlabel('Days in training');
ylabel('Consumed fraction');

% Row 2: IRI stats over learning
%------------------------------------------------------------
subplot(3,3,[4 5]);
boxplot_wrapper(days_cell, IRIs_corr, 'Notch', 'off', 'OutlierSize', 4);
% xlabel('Days in training');
ylabel({'Inter-reward interval (s)', 'Consumed trials only'});
grid on;
ylim([0 25]);

subplot(3,3,6);
plot(num_rewards_corr, 1./cellfun(@median, IRIs_corr, 'UniformOutput', true),...
    'ko', 'MarkerFaceColor', [0 0.5 0], 'MarkerSize', 6);
grid on;
xlabel('Num consumed rewards');
ylabel('1/median(IRI)');
% ylim([0 0.15]);

% Row 3: Average velocity over learning
%------------------------------------------------------------

% Time window for computing mean velocities
t1 = -3.0;
t2 = -0.5;
inds = find(t0==t1):find(t0==t2);

V_means_corr = cell(num_datasets, 1);
for k = 1:num_datasets
    % Compute the mean velocity over [t1, t2]
    Vk = V_corr{k};
    V_means_corr{k} = mean(Vk(:,inds), 2);
end

subplot(3,3,[7 8]);
boxplot_wrapper(days_cell, V_means_corr, 'OutlierSize', 4);
xlabel('Days in training');
ylabel({'Avg. velocity between',...
    sprintf('%.1f to %.1f s (cm/s)', t1, t2),...
    'Consumed trials only'});
grid on;
% ylim([0 50]);

subplot(3,3,9);
plot(num_rewards_corr, cellfun(@median, V_means_corr, 'UniformOutput', true),...
    'ko', 'MarkerFaceColor', [0 0.5 0], 'MarkerSize', 6);
grid on;
xlabel('Num consumed rewards');
ylabel('median(avg. velocity)');
% ylim([3 9]);