clear;

%%
fps = 30;
x_ticks = fps*(-2:6);
load('behavior.mat');
ls = cellfun(@sum, licks, 'UniformOutput', true);
min_l = min(ls);
max_l = max(ls);
l_range = [min_l max_l] + 1/10*(max_l-min_l)*[-1 1];

load('opto.mat');
ls_off = ls(trial_inds.off);
ls_real = ls(trial_inds.real);

hit_off = sum(rewarded(trial_inds.off))/length(trial_inds.off);
hit_real = sum(rewarded(trial_inds.real))/length(trial_inds.real);

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

first_licks = zeros(num_trials, num_aligned_time);
first_licks_times = zeros(num_trials);
for k = 1:num_trials
    fl = find(aligned_licks(k,:),1,'first');
    if ~isempty(fl)
        first_licks(k,fl) = 1;
        first_licks_times(k) = aligned_time(fl)/fps;
    else
        first_licks_times(k) = NaN;
    end
end

first_licks_off = first_licks(trial_inds.off,:);
first_licks_real = first_licks(trial_inds.real,:);

% Note: 'rmmissing' removes NaN entries
first_licks_times_off = rmmissing(first_licks_times(trial_inds.off));
first_licks_times_real = rmmissing(first_licks_times(trial_inds.real));

%%

suptitle(sprintf('%s: Licking across laser conditions', dirname));
corr_width = 10;
subplot(1,3,1);
imagesc(aligned_time, 1:num_trials, aligned_licks);
colormap([1 1 1; 0 0 0]);
xlabel('Frames relative to CS onset');
xticks(x_ticks);
ylabel('Trial index');
hold on;
plot([0 0], [0 num_trials], 'b--');
for k = 1:num_trials
    if rewarded(k)
        corr_color = 'g';
    else
        corr_color = 'r';
    end
    rectangle('Position', [aligned_time(end) k-0.5 corr_width 1], 'FaceColor', corr_color);
end
xlim([aligned_time(1) aligned_time(end)+corr_width]);
hold off;

subplot(3,3,2);
bar(trial_inds.off, ls_off, 'k', 'EdgeColor', 'none');
hold on;
bar(trial_inds.real, ls_real, 'r', 'EdgeColor', 'none');
% bar(trial_inds.sham, ls_sham, 'm', 'EdgeColor', 'none');
hold off;
ylabel('Total licks in trial');
grid on;
ylim(l_range);

subplot(3,6,5);
g = cell(160,1);
g(trial_inds.off) = {'off'};
g(trial_inds.real) = {'real'};
boxplot(ls, g, 'GroupOrder', {'off', 'real'});
ylabel('Total licks in trial');
% grid on;

subplot(3,6,6);
b = bar(categorical({'off', 'real'}), [hit_off hit_real], 0.75);
b.FaceColor = 'flat';
b.CData(1,:) = [0 0 0]; % 'k'
b.CData(2,:) = [1 0 0]; % 'r'
grid on;
ylim([0 1]);
set(gca,'YTick',0:0.1:1);
ylabel('Fraction rewarded trials');

%
subplot(3,3,5);
bar(aligned_time, mean(aligned_licks_off), 1, 'k');
ylabel('Licks / Trial (off)');
xlim(aligned_time([1 end]));
xticks(x_ticks);
title('ALL licks');
grid on;

subplot(3,3,6);
bar(aligned_time, sum(first_licks_off), 1, 'k');
ylabel('Licks (off)');
xlim(aligned_time([1 end]));
xticks(x_ticks);
legend(sprintf('Distr: %.2f \\pm %.2f s', mean(first_licks_times_off), std(first_licks_times_off)),...
    'Location', 'NorthEast');
title('FIRST licks');
grid on;

subplot(3,3,8);
bar(aligned_time, mean(aligned_licks_real), 1, 'r');
ylabel('Licks / Trial (real)');
xlim(aligned_time([1 end]));
xticks(x_ticks);
xlabel('Frames relative to CS onset');
grid on;

subplot(3,3,9);
bar(aligned_time, sum(first_licks_real), 1, 'r');
ylabel('Licks (real)');
xlim(aligned_time([1 end]));
xticks(x_ticks);
legend(sprintf('Distr: %.2f \\pm %.2f s', mean(first_licks_times_real), std(first_licks_times_real)),...
    'Location', 'NorthEast');
xlabel('Frames relative to CS onset');
grid on;
