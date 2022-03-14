function [V, R, t0] = show_alignment_to_us(bdata)
% Parse behavioral data with respect to the time of US.
%
% Here, 'bdata' is the behavior struct that is generated by the
% function `parse_ctxstr.m`

% Defaults
font_size = 18;

if ~exist('bdata', 'var')
    path_to_behavior = 'ctxstr.mat';
    bdata = load(path_to_behavior);
    bdata = bdata.behavior;
    fprintf('Loaded behavioral data from "%s"\n', path_to_behavior);
end

% Note: Assumes directory name is the dataset name
dataset_name = dirname;
num_rewards = length(bdata.us_times);
lick_times = bdata.lick_times;

response_window = 1; % s

% Note regarding 'dt' below: Uses the same temporal sampling rate as the  
% original velocity calculation.
% dt = bdata.velocity(2,1) - bdata.velocity(1,1);
dt = 0.05;
t0 = -4:dt:2;
NT = length(t0);

V = zeros(num_rewards, NT); % Velocity matrix
L = cell(num_rewards, 1); % Lick cell
R = false(num_rewards, 1); % 1 if mouse licked within 'response_window' of us
for k = 1:num_rewards
    us_time = bdata.us_times(k);
    t = t0 + us_time;
    
    % Resample velocity trace
    V(k,:) = interp1(bdata.velocity(:,1), bdata.velocity(:,2), t);
    
    % Find licks that occur within the time window
    ind1 = find(lick_times > t(1), 1, 'first');
    ind2 = find(lick_times < t(end), 1, 'last');
    lt = lick_times(ind1:ind2) - us_time; % Time relative to US
    L{k} = lt;
    
    % Licks within the response window?
    lt = lt(lt>0); 
    R(k) = any(lt<response_window);
end

num_correct = sum(R); % Licked within response window
num_incorrect = num_rewards - num_correct;

% Display results
figure;
subplot(3,2,[1 3]);
imagesc(t0, 1:num_rewards, V);
ylabel(sprintf('All trials (%d total)', num_rewards));
title(sprintf('%s: Velocity', dataset_name));
set(gca,'TickLength',[0 0]);
set(gca, 'FontSize', font_size);

v_avg = mean(V);
v_min = min([0 min(V(:))]);
v_max = max(V(:));
subplot(3,2,5);
shadedErrorBar(t0, v_avg, std(V)/sqrt(num_rewards));
hold on;
if num_correct >= 2 % Need at least 2 for STD
    V_corr = V(R,:);
    shadedErrorBar(t0, mean(V_corr), std(V_corr)/sqrt(num_correct), 'lineProps', {'Color', 'g', 'LineWidth', 1});
end
if num_incorrect >= 2
    V_incorr = V(~R,:);
    shadedErrorBar(t0, mean(V_incorr), std(V_incorr)/sqrt(num_incorrect), 'lineProps', {'Color', 'r', 'LineWidth', 1});
end
hold off;
grid on;
xlabel('Time relative to reward (s)');
ylabel('Velocity (mean\pms.e.m.)');
ylim(0.0*(v_max-v_min)*[-1 1] + [v_min v_max]);
set(gca,'TickLength',[0 0]);
set(gca, 'FontSize', font_size);
title(sprintf('All trials (%d); \\color{DarkGreen}Licks (%d); \\color{Red}No licks (%d)',...
    num_rewards, num_correct, num_incorrect));

subplot(3,2,[2 4]);
rectangle('Position', [0 0.5 response_window num_rewards+0.5],...
          'FaceColor', [1 1 0 0.3], 'EdgeColor', 'none');
hold on;
resp_ind_width = 0.2; % Size of the response indicator
for k = 1:num_rewards
    licks = L{k};
    num_licks_in_trial = length(licks);
    if num_licks_in_trial > 0
        plot(licks, k*ones(1,num_licks_in_trial), 'k.');
    end
    
    % Display response window
    if R(k)
        resp_color = 'g';
    else
        resp_color = 'r';
    end
    rectangle('Position', [t0(end) k-0.5 resp_ind_width 1],...
        'FaceColor', resp_color, 'EdgeColor', 'none');
end
hold off;
xlim([t0(1) t0(end)+resp_ind_width]);
ylim([0.5 num_rewards+0.5]);
xlabel(sprintf('Response window = %.1f s (highlighted)', response_window));
set(gca,'YDir','Reverse');
ylabel(sprintf('Lick responses in %d of %d trials (%.1f%%)',...
    sum(R), num_rewards, sum(R)/num_rewards*100));
title(sprintf('%s: Licks', dataset_name));
set(gca,'TickLength',[0 0]);
set(gca, 'FontSize', font_size);

all_lick_times = cell2mat(L);
subplot(3,2,6);
histogram(all_lick_times, t0, 'FaceColor', 0.25*[1 1 1]);
xlim([t0(1) t0(end)+resp_ind_width]);
xlabel('Time relative to reward (s)');
ylabel('Lick counts');
grid on;
set(gca,'TickLength',[0 0]);
title('All trials');
set(gca, 'FontSize', font_size);

end % align_to_us