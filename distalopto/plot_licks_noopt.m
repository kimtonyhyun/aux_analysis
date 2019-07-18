clear;

%%
fps = 30;
x_ticks = fps*(-2:6);
load('behavior.mat');
ls = cellfun(@sum, licks, 'UniformOutput', true);
min_l = min(ls);
max_l = max(ls);
l_range = [min_l max_l] + 1/10*(max_l-min_l)*[-1 1];

num_trials = size(rewarded);
trial_inds.off = 1:num_trials;

% Specializations for Pavlovian variant of the task. Note: a trial is
% marked as "rewarded" if there is a detected lick within the trial.
rewarded = cellfun(@any, licks, 'UniformOutput', true);

ls_off = ls(trial_inds.off);

hit_off = sum(rewarded(trial_inds.off))/length(trial_inds.off);

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

% Note: 'rmmissing' removes NaN entries
first_licks_times_off = rmmissing(first_licks_times(trial_inds.off));

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

subplot(3,6,[3 4 5]);
bar(trial_inds.off, ls_off, 'k', 'EdgeColor', 'none');
ylabel('Total licks in trial');
grid on;
ylim(l_range);

subplot(3,6,6);
g = cell(num_trials,1);
g(trial_inds.off) = {'off'};
boxplot(ls, g);

subplot(3,3,[5 6]);
bar(aligned_time, mean(aligned_licks_off), 1, 'k');
ylabel('Licks / Trial');
xlim(aligned_time([1 end]));
xticks(x_ticks);
title('ALL licks');
grid on;

subplot(3,3,[8 9]);
bar(aligned_time, sum(first_licks_off), 1, 'k');
ylabel('Licks');
xlim(aligned_time([1 end]));
xticks(x_ticks);
legend(sprintf('Distr: %.2f \\pm %.2f s', mean(first_licks_times_off), std(first_licks_times_off)),...
    'Location', 'NorthEast');
title('FIRST licks');
xlabel('Frames relative to CS onset');
grid on;


