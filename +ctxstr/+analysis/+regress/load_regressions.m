clear all;

% Format: {Day-idx, session-directory}
oh08 = {2, 'oh08-0305';
        4, 'oh08-0307';
        5, 'oh08-0308';
        6, 'oh08-0309';
        7, 'oh08-0310';
        8, 'oh08-0311';
       };

oh12 = {2, 'oh12-0124';
        3, 'oh12-0125';
        5, 'oh12-0127';
        7, 'oh12-0129';
        8, 'oh12-0130';
       };

oh15 = {2, 'oh15-0730';
        3, 'oh15-0731';
        4, 'oh15-0801';
        5, 'oh15-0802';
        6, 'oh15-0804';
        7, 'oh15-0805';
        8, 'oh15-0806';
       };

oh20 = {2, 'oh20-1008';
        3, 'oh20-1009';
        5, 'oh20-1011';
        6, 'oh20-1012';
        7, 'oh20-1013';
        8, 'oh20-1014';
       };

oh21 = {1, 'oh21-1007';
        2, 'oh21-1008';
        3, 'oh21-1009';
        4, 'oh21-1010';
        5, 'oh21-1011';
        6, 'oh21-1012';
        7, 'oh21-1013';
        8, 'oh21-1014';
       };

oh27 = {2, 'oh27-0202';
        3, 'oh27-0203';
        4, 'oh27-0204';
        5, 'oh27-0205';
        6, 'oh27-0206';
        7, 'oh27-0207';
        8, 'oh27-0208';
       };

oh28 = {1, 'oh28-0202';
        2, 'oh28-0203';
        4, 'oh28-0205';
        5, 'oh28-0206';
        6, 'oh28-0207';
        7, 'oh28-0208';
        8, 'oh28-0209';
       };

sources = eval(dirname); % If the dirname is 'oh28', then retrieves the variable named 'oh28'

num_sources = size(sources,1);
mouse_name = dirname;

% Load data
rdata = cell(num_sources,1);
tdt_data = cell(num_sources,1);
for k = 1:num_sources
    path_to_reg_mat = fullfile(sources{k,2}, 'regression.mat');
    fprintf('%s: Loading "%s"...\n', datestr(now), path_to_reg_mat);
    rdata{k} = load(path_to_reg_mat);

    % Get striatum tdTomato labeling from resampled_data
    path_to_tdt = fullfile(sources{k,2}, 'resampled_data.mat');
    temp = load(path_to_tdt, 'str_info');
    tdt_data{k} = temp.str_info.tdt;
end
fprintf('Done!\n');

%%

% model_no = 6; % The {motion, reward} model
% model_no = 7; % {velocity, reward}
model_no = 8; % {velocity, motion, reward}
% model_no = 10; % {velocity, accel, lick_rate, motion, reward}
model_desc = rdata{1}.models{model_no}.get_desc;

ctx_R2s = cell(num_sources, 1);
str_R2s = cell(num_sources, 1);

fprintf('* * *\n%s, model=%s\nDay CtxR2Median StrR2Median StrTdtPosR2Median StrTdtNegR2Median\n', mouse_name, model_desc)
for k = 1:num_sources
    fit_performed = rdata{k}.ctx_fit.results.fit_performed;
    ctx_R2s{k} = rdata{k}.ctx_fit.results.R2(fit_performed, model_no);

    fit_performed = rdata{k}.str_fit.results.fit_performed;
    str_R2s{k} = rdata{k}.str_fit.results.R2(fit_performed, model_no);

    tdt_pos = false(size(fit_performed));
    tdt_pos(tdt_data{k}.pos) = true;
    str_tdtpos_R2s = rdata{k}.str_fit.results.R2(tdt_pos & fit_performed, model_no);

    tdt_neg = false(size(fit_performed));
    tdt_neg(tdt_data{k}.neg) = true;
    str_tdtneg_R2s = rdata{k}.str_fit.results.R2(tdt_neg & fit_performed, model_no);

    % Format: [Day CtxR2Median StrR2Median]
    fprintf('%d %.4f %.4f %.4f %.4f; %% %s\n',...
        sources{k,1},...
        median(ctx_R2s{k}),...
        median(str_R2s{k}),...
        median(str_tdtpos_R2s),...
        median(str_tdtneg_R2s),...
        sources{k,2});
end
clear fit_performed;

% Plot results
clf;

ax1 = subplot(121);
boxplot_wrapper([sources{:,1}], ctx_R2s);
grid on;
xlabel('Training day');
ylabel('Test R^2');
title({sprintf('%s-ctx', mouse_name),...
       sprintf('model=%s', model_desc)},...
      'Interpreter', 'none');

ax2 = subplot(122);
boxplot_wrapper([sources{:,1}], str_R2s);
grid on;
xlabel('Training day');
ylabel('Test R^2');
title({sprintf('%s-str', mouse_name),...
       sprintf('model=%s', model_desc)},...
      'Interpreter', 'none');

linkaxes([ax1 ax2], 'y');
ylim([0 0.6]);
set([ax1 ax2], 'FontSize', 14);