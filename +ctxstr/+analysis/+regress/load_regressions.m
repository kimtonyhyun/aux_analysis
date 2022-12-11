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
tdt_data = cell(num_days,1);

ctx_map = cell(num_days,1);
str_map = cell(num_days,1);

for k = 1:num_days
    path_to_source = sources{k,2};

    path_to_reg_mat = fullfile(path_to_source, 'regression.mat');
    fprintf('%s: Loading "%s"...\n', datetime, path_to_reg_mat);
    regs{k} = load(path_to_reg_mat);

    % Get auxiliary information from resampled_data.mat
    path_to_tdt = fullfile(path_to_source, 'resampled_data.mat');
    temp = load(path_to_tdt, 'ctx_info', 'str_info');

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

    % Format: [Day CtxR2Median StrR2Median]
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
        day_color = 'c';
end
reg = regs{days==day};
[ctx_top_fits, str_top_fits] = ctxstr.analysis.regress.get_top_fits(reg, model_no);

%% Visualize a specific fit (defined by cell_idx × model_no × split_no)

brain_area = 'str'; % 'ctx' or 'str'
cell_idx = 43;
split_no = 1;

% Retrieve the regression data for the chosen day
reg = regs{days==day}; 

% Show the cell raster
figure(2);
ctxstr.analysis.regress.visualize_binned_raster(reg, brain_area, cell_idx);

% Show the detailed fit
figure(3);
ctxstr.analysis.regress.visualize_fit(reg, brain_area, cell_idx, model_no, split_no);

% Track the chosen cell (above) across days
%------------------------------------------------------------
switch brain_area
    case 'ctx'
        matches = match_data.ctx_matches;
        ax = ax_ctx;
        map = ctx_map;

    case 'str'
        matches = match_data.str_matches;
        ax = ax_str;
        map = str_map;
end

% Format: [Day, Cell#, ActiveFrac, R2]
tracked_data = zeros(num_days, 4);
tidx = 0;

if exist('figure_idx', 'var')
    close(4:figure_idx);
end
figure_idx = 4;

cprintf('blue', 'Matching Day %d, %s cell=%d...\n', day, brain_area, cell_idx);
for d = days
    if d == day
        active_frac = 100*ctxstr.analysis.regress.get_active_frac(reg, brain_area, cell_idx);
        R2_val = ctxstr.analysis.regress.get_R2(reg, brain_area, cell_idx, model_no);
        fprintf('- Day %d: Selected %s cell=%d (AF=%.1f%%, R^2=%.4f)\n',...
            d, brain_area, cell_idx, active_frac, R2_val);

        tidx = tidx + 1;
        tracked_data(tidx,:) = [d, cell_idx, active_frac, R2_val];

        figure(figure_idx); figure_idx = figure_idx + 1;
        ctxstr.analysis.regress.visualize_binned_raster(reg, brain_area, cell_idx,...
            'fig_name', sprintf('Day %d', d));
    else
        % Matches are computed with respect to REC indices, whereas
        % regressions are performed with respect to IND indices. So we nee
        % to convert and convert back.
        cell_idx_rec = map{days==day}.ind2rec(cell_idx);
        m = matches{day, d}{cell_idx_rec};
        if isempty(m)
            fprintf('- Day %d: No match\n', d);
        else
            other_reg = regs{days==d};
            other_cell_idx = map{days==d}.rec2ind(m(1));
            other_active_frac = 100*ctxstr.analysis.regress.get_active_frac(other_reg, brain_area, other_cell_idx);
            other_R2_val = ctxstr.analysis.regress.get_R2(other_reg, brain_area, other_cell_idx, model_no);

            tidx = tidx + 1;
            tracked_data(tidx,:) = [d, other_cell_idx, other_active_frac, other_R2_val];

            fprintf('- Day %d: Matched to %s cell=%d (AF=%.1f%%, R^2=%.4f)\n',...
                d, brain_area, other_cell_idx, other_active_frac, other_R2_val);
    
            figure(figure_idx); figure_idx = figure_idx + 1;
            ctxstr.analysis.regress.visualize_binned_raster(other_reg, brain_area, other_cell_idx,...
                'fig_name', sprintf('Day %d', d));
        end
    end
end
tracked_data = tracked_data(1:tidx,:);

% Show the tracked R2 on the appropriate summary plot
figure(1);
subplot(ax);
hold on;
plot(tracked_data(:,1), tracked_data(:,4), '.-', 'Color', day_color);
hold off;