clear;

load('opto.mat');
off_trials = trial_inds.off;
on_condition = 'real';
on_trials = getfield(trial_inds, on_condition);

%%
fps = 30;
x_ticks = fps*(-2:6);
load('behavior.mat');
ls = cellfun(@sum, licks, 'UniformOutput', true);
min_l = min(ls);
max_l = max(ls);
l_range = [min_l max_l] + 1/10*(max_l-min_l)*[-1 1];

ls_off = ls(off_trials);
ls_on = ls(on_trials);

hit_off = sum(rewarded(off_trials))/length(off_trials);
hit_on = sum(rewarded(on_trials))/length(on_trials);

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

aligned_licks_off = aligned_licks(off_trials,:);
aligned_licks_on = aligned_licks(on_trials,:);

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

first_licks_off = first_licks(off_trials,:);
first_licks_on = first_licks(on_trials,:);

% Note: 'rmmissing' removes NaN entries
first_licks_times_off = rmmissing(first_licks_times(off_trials));
first_licks_times_on = rmmissing(first_licks_times(on_trials));

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
bar(off_trials, ls_off, 'k', 'EdgeColor', 'none');
hold on;
bar(on_trials, ls_on, 'r', 'EdgeColor', 'none');
% bar(trial_inds.sham, ls_sham, 'm', 'EdgeColor', 'none');
hold off;
ylabel('Total licks in trial');
grid on;
ylim(l_range);

subplot(3,6,5);
ls_sub = [ls_off; ls_on];
g = cell(length(ls_sub),1);
N_off = length(ls_off);
g(1:N_off) = {'off'};
g(N_off+1:end) = {on_condition};
% g = cell(num_trials,1);
% g(off_trials) = {'off'};
% g(on_trials) = {'on'};
boxplot(ls_sub, g, 'GroupOrder', {'off', on_condition});
ylabel('Total licks in trial');
grid on;

subplot(3,6,6);
b = bar(categorical({'off', strrep(on_condition,'_','\_')}), [hit_off hit_on], 0.75);
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
bar(aligned_time, mean(aligned_licks_on), 1, 'r');
ylabel(sprintf('Licks / Trial (%s)',...
    strrep(on_condition,'_','\_')));
xlim(aligned_time([1 end]));
xticks(x_ticks);
xlabel('Frames relative to CS onset');
grid on;

subplot(3,3,9);
bar(aligned_time, sum(first_licks_on), 1, 'r');
ylabel(sprintf('Licks (%s)',...
    strrep(on_condition,'_','\_')));
xlim(aligned_time([1 end]));
xticks(x_ticks);
legend(sprintf('Distr: %.2f \\pm %.2f s', mean(first_licks_times_on), std(first_licks_times_on)),...
    'Location', 'NorthEast');
xlabel('Frames relative to CS onset');
grid on;
