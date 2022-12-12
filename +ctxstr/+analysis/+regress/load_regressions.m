clear all; close all;

mouse_name = lower(dirname);

% Manually list datasets with regression data. TODO: Consider just scanning
% the directory for 'regression.mat'?
% Format: {Day-idx, session-directory}
switch mouse_name
    case 'oh08'
        sources = {2, 'oh08-0305';
                   4, 'oh08-0307';
                   5, 'oh08-0308';
                   6, 'oh08-0309';
                   7, 'oh08-0310';
                   8, 'oh08-0311';
                  };

    case 'oh12'
        sources = {2, 'oh12-0124';
                   3, 'oh12-0125';
                   5, 'oh12-0127';
                   7, 'oh12-0129';
                   8, 'oh12-0130';
                  };

    case 'oh15'
        sources = {2, 'oh15-0730';
                   3, 'oh15-0731';
                   4, 'oh15-0801';
                   5, 'oh15-0802';
                   6, 'oh15-0804';
                   7, 'oh15-0805';
                   8, 'oh15-0806';
                  };

    case 'oh20'
        sources = {2, 'oh20-1008';
                   3, 'oh20-1009';
                   5, 'oh20-1011';
                   6, 'oh20-1012';
                   7, 'oh20-1013';
                   8, 'oh20-1014';
                  };

    case 'oh21'
        sources = {1, 'oh21-1007';
                   2, 'oh21-1008';
                   3, 'oh21-1009';
                   4, 'oh21-1010';
                   5, 'oh21-1011';
                   6, 'oh21-1012';
                   7, 'oh21-1013';
                   8, 'oh21-1014';
                  };

    case 'oh27'
        sources = {2, 'oh27-0202';
                   3, 'oh27-0203';
                   4, 'oh27-0204';
                   5, 'oh27-0205';
                   6, 'oh27-0206';
                   7, 'oh27-0207';
                   8, 'oh27-0208';
                  };

    case 'oh28'
        sources = {1, 'oh28-0202';
                   2, 'oh28-0203';
                   4, 'oh28-0205';
                   5, 'oh28-0206';
                   6, 'oh28-0207';
                   7, 'oh28-0208';
                   8, 'oh28-0209';
                  };
end

days = [sources{:,1}];
num_days = length(days);

% Load regression data
regs = cell(num_days,1);

% These variables are loaded from the "resampled_data" of each dataset.
% The *_map variables are required to interface to cell matching data in
% "all_matches.mat".
tdt_data = cell(num_days,1);
ctx_map = cell(num_days,1);
str_map = cell(num_days,1);

for k = 1:num_days
    path_to_source = sources{k,2};

    path_to_reg_mat = fullfile(path_to_source, 'regression.mat');
    fprintf('%s: Loading "%s"...\n', datetime, path_to_reg_mat);
    regs{k} = load(path_to_reg_mat);

    % Get auxiliary information from 'resampled_data'
    path_to_resampled = fullfile(path_to_source, 'resampled_data.mat');
    temp = load(path_to_resampled, 'ctx_info', 'str_info');

    ctx_map{k} = struct('ind2rec', temp.ctx_info.ind2rec, 'rec2ind', temp.ctx_info.rec2ind);
    str_map{k} = struct('ind2rec', temp.str_info.ind2rec, 'rec2ind', temp.str_info.rec2ind);

    tdt_data{k} = temp.str_info.tdt;
    if isempty(tdt_data{k})
        cprintf('red', 'Warning: tdTomato labels missing for "%s"\n', path_to_source);
    end
end
fprintf('Done!\n'); clear temp path_to_*;

% Load cell matching data. Note that match matrices are computed with
% respect to 'rec' cell indices, whereas regressions are performed only for
% classified cells.
match_data = load('all_matches.mat');

% Dock all figures for convenience
set(0, 'DefaultFigureWindowStyle', 'docked');

%% Collect R2 data and other stats for chosen model across days

model_no = 6; % The {motion, reward} model
% model_no = 7; % {velocity, reward}
% model_no = 8; % {velocity, motion, reward}
% model_no = 10; % {velocity, accel, lick_rate, motion, reward}

ctx_R2s = cell(num_days, 1);
str_R2s = cell(num_days, 1);

ctx_cell_counts = zeros(num_days, 2); % Format: [Num-fitted Num-total]
str_cell_counts = zeros(num_days, 2);

model_desc = regs{1}.models{model_no}.get_desc;
fprintf('* * *\n%s, model=%s\n', mouse_name, model_desc)
fprintf('Day CtxR2Median StrR2Median StrTdtPosR2Median StrTdtNegR2Median\n');
for k = 1:num_days
    fit_performed = regs{k}.ctx_fit.results.fit_performed;
    R2_vals = regs{k}.ctx_fit.results.R2(fit_performed, model_no);

    ctx_R2s{k} = [R2_vals find(fit_performed)]; % [R2_val, cell_id]
    ctx_cell_counts(k,:) = [sum(fit_performed) length(fit_performed)];

    fit_performed = regs{k}.str_fit.results.fit_performed;
    R2_vals = regs{k}.str_fit.results.R2(fit_performed, model_no);

    str_R2s{k} = [R2_vals find(fit_performed)];
    str_cell_counts(k,:) = [sum(fit_performed) length(fit_performed)];

    tdt_pos = false(size(fit_performed));
    tdt_pos(tdt_data{k}.pos) = true;
    str_tdtpos_R2s = regs{k}.str_fit.results.R2(tdt_pos & fit_performed, model_no);

    tdt_neg = false(size(fit_performed));
    tdt_neg(tdt_data{k}.neg) = true;
    str_tdtneg_R2s = regs{k}.str_fit.results.R2(tdt_neg & fit_performed, model_no);

    % Print to console
    fprintf('%d %.4f %.4f %.4f %.4f; %% %s\n',...
        sources{k,1},...
        median(ctx_R2s{k}(:,1)),...
        median(str_R2s{k}(:,1)),...
        median(str_tdtpos_R2s),...
        median(str_tdtneg_R2s),...
        sources{k,2});
end
clear fit_performed R2_vals;

%% Plot cross-day stats for chosen model

figure(1);
[ax_ctx, ax_str] = ctxstr.analysis.regress.visualize_cross_day_stats(mouse_name, model_desc,...
    days, ctx_R2s, ctx_cell_counts, str_R2s, str_cell_counts);

%% Find top cells for a given day

day = 8;
switch day
    case {1, 2}
        day_color = 'm';
    case {7, 8}
        day_color = [0 0.5 0];
    otherwise
        day_color = 'k';
end
reg = regs{days==day};
[ctx_top_fits, str_top_fits] = ctxstr.analysis.regress.get_top_fits(reg, model_no);
fprintf('Top fits computed for Day=%d\n', day);

%% Visualize a specific fit (defined by cell_idx × model_no × split_no)

brain_area = 'ctx'; % 'ctx' or 'str'
cell_idx = 18;

% Track the chosen cell across days
%------------------------------------------------------------
switch brain_area
    case 'ctx'
        ax = ax_ctx;
        tracked_cell = ctxstr.analysis.track_cell(day, cell_idx, days, ctx_map, match_data.ctx_matches);

    case 'str'
        ax = ax_str;
        tracked_cell = ctxstr.analysis.track_cell(day, cell_idx, days, str_map, match_data.str_matches);
end

% Then track regression stats. Format: [Day, Cell#, ActiveFrac, R2]
tracked_stats = ctxstr.analysis.regress.track_stats(days, regs, brain_area, tracked_cell, model_no);

% Show the cell raster
% figure(2);
% ctxstr.analysis.regress.visualize_binned_raster(reg, brain_area, cell_idx);

% Show the detailed fit
% figure(3);
% split_no = 1;
% ctxstr.analysis.regress.visualize_fit(reg, brain_area, cell_idx, model_no, split_no);

% % Plot the tracked rasters
% if exist('figure_idx', 'var')
%     close(4:figure_idx);
% end
% figure_idx = 3;
% 
% cprintf('blue', 'Tracked Day %d, %s cell=%d...\n', day, brain_area, cell_idx);
% for d = days
%     k = find(tracked_stats(:,1)==d);
%     if isempty(k)
%         fprintf('- Day %d: No match\n', d);
%     else
%         c = tracked_stats(k,2);
%         fprintf('- Day %d: %s cell=%3d (AF=%.1f%%, R^2=%.4f)\n',...
%             d, brain_area, c, tracked_stats(k,3), tracked_stats(k,4));
% 
%         figure_idx = figure_idx + 1;
%         figure(figure_idx);
%         ctxstr.analysis.regress.visualize_binned_raster(regs{days==d}, brain_area, c,...
%             'fig_name', sprintf('Day %d', d));
%     end
% end

% Show the tracked R2 on the appropriate summary plot
figure(1);
subplot(ax);
hold on;
plot(tracked_stats(:,1), tracked_stats(:,4), '.-',...
    'Color', day_color, 'MarkerSize', 14);
hold off;