clear;

%%
load('behavior.mat');
vs = cellfun(@mean, velocity, 'UniformOutput', true);
min_v = min(vs);
max_v = max(vs);
v_range = [min_v max_v] + 1/10*(max_v-min_v)*[-1 1];

load('opto.mat');
num_trials = length(trial_inds.off) + length(trial_inds.real) + length(trial_inds.sham);
vs_off = vs(trial_inds.off);
vs_real = vs(trial_inds.real);
vs_sham = vs(trial_inds.sham);

%
subplot(4,3,[1 2]);
bar(trial_inds.off, vs_off, 'k', 'EdgeColor', 'none');
hold on;
bar(trial_inds.real, vs_real, 'r', 'EdgeColor', 'none');
bar(trial_inds.sham, vs_sham, 'm', 'EdgeColor', 'none');
hold off;
xlabel('Trial index');
ylabel('Mean velocity (cm/s)');
grid on;
ylim(v_range);

%
subplot(4,3,3);
g = cell(num_trials,1);
g(trial_inds.off) = {'off'};
g(trial_inds.real) = {'real'};
% g(trial_inds.sham) = {'sham'};
boxplot(vs, g, 'GroupOrder', {'off', 'real'});

%
bins = linspace(min_v, max_v, 50);

subplot(4,1,2);
histogram(vs_off, bins, 'FaceColor', 'k');
title(sprintf('off trials (%d)', length(trial_inds.off)));
ylabel('Num trials');
grid on;

subplot(4,1,3);
histogram(vs_real, bins, 'FaceColor', 'r');
title(sprintf('real trials (%d)', length(trial_inds.real)));
ylabel('Num trials');
grid on;

subplot(4,1,4);
histogram(vs_sham, bins, 'FaceColor', 'm');
title(sprintf('sham trials (%d)', length(trial_inds.sham)));
ylabel('Num trials');
grid on;
xlabel('Velocity (cm/s)');

%%
suptitle(sprintf('%s: Velocities across laser conditions', dirname));

%%
velocity_filter = @(v) (-0.5<v)&(v<5.5);

filtered_trial_inds.off = trial_inds.off(velocity_filter(vs_off));
filtered_trial_inds.real = trial_inds.real(velocity_filter(vs_real));
filtered_trial_inds.sham = trial_inds.sham(velocity_filter(vs_sham));

%%

filtered_laser_inds.off = frame_segments_to_list(...
    ds.trial_indices(filtered_trial_inds.off,[1 end]));
filtered_laser_inds.real = frame_segments_to_list(...
    ds.trial_indices(filtered_trial_inds.real,[1 end]));
filtered_laser_inds.sham = frame_segments_to_list(...
    ds.trial_indices(filtered_trial_inds.sham,[1 end]));
