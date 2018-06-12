clear;

%%
load('behavior.mat');
ls = cellfun(@sum, licks, 'UniformOutput', true);
min_l = min(ls);
max_l = max(ls);
l_range = [min_l max_l] + 1/10*(max_l-min_l)*[-1 1];

load('opto.mat');
ls_off = ls(trial_inds.off);
ls_real = ls(trial_inds.real);
ls_sham = ls(trial_inds.sham);

hit_off = sum(rewarded(trial_inds.off))/length(trial_inds.off);
hit_real = sum(rewarded(trial_inds.real))/length(trial_inds.real);
hit_sham = sum(rewarded(trial_inds.sham))/length(trial_inds.sham);

%%

% Align licks to CS onset
frame_indices = get_trial_frame_indices('distalopto.txt');
num_trials = size(frame_indices,1);
[pre_offset, post_offset] = compute_frame_offsets(frame_indices, 1:num_trials, frame_indices(:,2));
aligned_time = pre_offset:post_offset;
num_aligned_time = length(aligned_time);

aligned_licks = zeros(num_trials, num_aligned_time);
for k = 1:num_trials
    l = licks{k};
    cs_frame = frame_indices(k,2)-frame_indices(k,1)+1;
    frames = cs_frame + aligned_time;
    aligned_licks(k,:) = l(frames);
end

aligned_licks_off = aligned_licks(trial_inds.off,:);
aligned_licks_real = aligned_licks(trial_inds.real,:);
aligned_licks_sham = aligned_licks(trial_inds.sham,:);

first_licks = zeros(num_trials, num_aligned_time);
for k = 1:num_trials
    fl = find(aligned_licks(k,:),1,'first');
    first_licks(k,fl) = 1;
end

first_licks_off = first_licks(trial_inds.off,:);
first_licks_real = first_licks(trial_inds.real,:);
first_licks_sham = first_licks(trial_inds.sham,:);

first_licks_off_mean = aligned_time * sum(first_licks_off)' / length(trial_inds.off);
first_licks_real_mean = aligned_time * sum(first_licks_real)' / length(trial_inds.real);
first_licks_sham_mean = aligned_time * sum(first_licks_sham)' / length(trial_inds.sham);

%%

suptitle(sprintf('%s: Licking across laser conditions', dirname));
corr_width = 10;
subplot(1,3,1);
imagesc(aligned_time, 1:num_trials, aligned_licks);
colormap([1 1 1; 0 0 0]);
xlabel('Frames relative to CS onset');
xticks(-60:30:180);
ylabel('Trial index');
hold on;
plot([0 0], [0 num_trials], 'b--');
for k = 1:num_trials
    if rewarded(k)
        corr_color = 'g';
    else
        corr_color = 'r';
    end
    rectangle('Position', [180 k-0.5 corr_width 1], 'FaceColor', corr_color);
end
xlim([aligned_time(1) aligned_time(end)+corr_width]);
hold off;

subplot(4,3,2);
bar(trial_inds.off, ls_off, 'k', 'EdgeColor', 'none');
hold on;
bar(trial_inds.real, ls_real, 'r', 'EdgeColor', 'none');
bar(trial_inds.sham, ls_sham, 'm', 'EdgeColor', 'none');
hold off;
ylabel('Total licks in trial');
grid on;
ylim(l_range);

subplot(4,6,5);
g = cell(160,1);
g(trial_inds.off) = {'off'};
g(trial_inds.real) = {'real'};
g(trial_inds.sham) = {'sham'};
boxplot(ls, g, 'GroupOrder', {'off', 'real', 'sham'});
ylabel('Total licks in trial');
% grid on;

subplot(4,6,6);
b = bar(categorical({'off', 'real', 'sham'}), [hit_off hit_real hit_sham], 0.75);
b.FaceColor = 'flat';
b.CData(1,:) = [0 0 0]; % 'k'
b.CData(2,:) = [1 0 0]; % 'r'
b.CData(3,:) = [1 0 1]; % 'm'
grid on;
ylim([0 1]);
set(gca,'YTick',0:0.1:1);
ylabel('Fraction rewarded trials');

%
subplot(4,3,5);
bar(aligned_time, mean(aligned_licks_off), 1, 'k');
ylabel('Licks / Trial (off)');
xlim(aligned_time([1 end]));
xticks(-60:30:180);
title('ALL licks');
grid on;

subplot(4,3,6);
bar(aligned_time, sum(first_licks_off), 1, 'k');
ylabel('Licks (off)');
xlim(aligned_time([1 end]));
xticks(-60:30:180);
legend(sprintf('\\mu = %.1f', first_licks_off_mean), 'Location', 'NorthEast');
title('FIRST licks');
grid on;

subplot(4,3,8);
bar(aligned_time, mean(aligned_licks_real), 1, 'r');
ylabel('Licks / Trial (real)');
xlim(aligned_time([1 end]));
xticks(-60:30:180);
grid on;

subplot(4,3,9);
bar(aligned_time, sum(first_licks_real), 1, 'r');
ylabel('Licks (real)');
xlim(aligned_time([1 end]));
xticks(-60:30:180);
legend(sprintf('\\mu = %.1f', first_licks_real_mean), 'Location', 'NorthEast');
grid on;

subplot(4,3,11);
bar(aligned_time, mean(aligned_licks_sham), 1, 'm');
ylabel('Licks / Trial (sham)');
xlim(aligned_time([1 end]));
xticks(-60:30:180);
xlabel('Frames relative to CS onset');
grid on;

subplot(4,3,12);
bar(aligned_time, sum(first_licks_sham), 1, 'm');
ylabel('Licks (sham)');
xlim(aligned_time([1 end]));
xticks(-60:30:180);
legend(sprintf('\\mu = %.1f', first_licks_sham_mean), 'Location', 'NorthEast');
xlabel('Frames relative to CS onset');
grid on;

