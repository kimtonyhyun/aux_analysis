%% Resample traces with a common timebase, then compute pairwise correlations

trials_to_use = st_trial_inds;

resampled_ctx_traces = cell(1, num_all_trials);
resampled_str_traces = cell(1, num_all_trials);
common_time = cell(1, num_all_trials);
for k = trials_to_use
    trial = trials(k);
    trial_time = [trial.start_time trial.us_time];
    
    [ctx_traces_k, ctx_times_k] = ctxstr.core.get_traces_by_time(ctx, trial_time);
    [str_traces_k, str_times_k] = ctxstr.core.get_traces_by_time(str, trial_time);
    
    if any(isnan(ctx_traces_k(:))) || any(isnan(str_traces_k(:)))
        trials_to_use = setdiff(trials_to_use, k);
        fprintf('Omitting Trial %d from correlation calculation due to NaNs\n', k);
    else
        [resampled_ctx_traces{k}, resampled_str_traces{k}, common_time{k}] = ctxstr.core.resample_ctxstr_traces(...
            ctx_traces_k, ctx_times_k, str_traces_k, str_times_k);
        
        % Needed for cell2mat concatenation (below), if working with Ca2+
        % traces which are stored as single
        resampled_ctx_traces{k} = double(resampled_ctx_traces{k});
        resampled_str_traces{k} = double(resampled_str_traces{k});
    end
end

cont_ctx_traces = cell2mat(resampled_ctx_traces); % [cells x time]
cont_str_traces = cell2mat(resampled_str_traces);

% Pearson correlations
C_ctx = corr(cont_ctx_traces');
C_str = corr(cont_str_traces');
C_ctxstr = corr(cont_ctx_traces', cont_str_traces');

%% Visualization #1: Correlation matrices and distribution of correlation values

num_outliers_to_show = 10;
corr_scale = 0.5*[-1 1];
histogram_bins = linspace(-1, 1, 200); % Number of elements should be even, to properly capture 0
font_size = 18;

sp = @(m,n,p) subtightplot(m, n, p, 0.04, 0.03, 0.04); % Gap, Margin-X, Margin-Y

% figure;
sp(2,3,1);
imagesc(tril(C_ctx,-1), corr_scale);
colormap redblue;
axis image;
xlabel('Ctx neurons');
ylabel(sprintf('Ctx neurons (%d total)', num_ctx_cells));
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);
title(sprintf('%s ctx-ctx correlations', dataset_name));

sp(2,3,2);
imagesc(tril(C_str,-1), corr_scale);
axis image;
xlabel('Str neurons');
ylabel(sprintf('Str neurons (%d total)', num_str_cells));
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);
title('str-str correlations');

sp(2,3,3);
imagesc(C_ctxstr, corr_scale);
axis image;
xlabel('Str neurons');
ylabel('Ctx neurons');
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);
colorbar;
title('ctx-str correlations');

C_ctx_vals = C_ctx(tril(true(num_ctx_cells),-1));
C_str_vals = C_str(tril(true(num_str_cells),-1));
C_ctxstr_vals = C_ctxstr(:);

C_ctx_counts = hist(C_ctx_vals, histogram_bins) / length(C_ctx_vals);
C_str_counts = hist(C_str_vals, histogram_bins) / length(C_str_vals);
C_ctxstr_counts = hist(C_ctxstr_vals, histogram_bins) / length(C_ctxstr_vals);

sp2 = @(m,n,p) subtightplot(m, n, p, 0.01, 0.08, 0.04); % Gap, Margin-X, Margin-Y

ax4 = sp2(6,1,4);
h_ctx = histogram(C_ctx_vals, histogram_bins, ...
    'FaceColor', 'k', 'EdgeColor', 'none');
y_lims = [0 1.05*max(h_ctx.BinCounts)];
hold on;
plot_vertical_lines(maxk(C_ctx_vals, num_outliers_to_show), y_lims, 'k:');
plot_vertical_lines(mink(C_ctx_vals, num_outliers_to_show), y_lims, 'k:');
hold off;
ylim(y_lims);
ylabel({'Ctx-ctx \rho', 'counts'});
set(gca, 'XTickLabel', {}, 'YTickLabel', {});
set(gca, 'YTick', []);
ax5 = sp2(6,1,5);
h_str = histogram(C_str_vals, histogram_bins, ...
    'FaceColor', 'm', 'EdgeColor', 'none');
y_lims = [0 1.05*max(h_str.BinCounts)];
hold on;
plot_vertical_lines(maxk(C_str_vals, num_outliers_to_show), y_lims, 'm:');
plot_vertical_lines(mink(C_str_vals, num_outliers_to_show), y_lims, 'm:');
hold off;
ylim(y_lims);
ylabel({'Str-str \rho', 'counts'});
set(gca, 'XTickLabel', {}, 'YTickLabel', {});
set(gca, 'YTick', []);
ax6 = sp2(6,1,6);
h_ctxstr = histogram(C_ctxstr_vals, histogram_bins,...
    'FaceColor', 'b', 'EdgeColor', 'none');
y_lims = [0 1.05*max(h_ctxstr.BinCounts)];
hold on;
plot_vertical_lines(maxk(C_ctxstr_vals, num_outliers_to_show), y_lims, 'b:');
plot_vertical_lines(mink(C_ctxstr_vals, num_outliers_to_show), y_lims, 'b:');
hold off;
ylim(y_lims);
ylabel({'Ctx-str \rho',  'counts'});
xlabel('Correlation \rho');
set(gca, 'YTickLabel', {});
set(gca, 'YTick', []);
set([ax4 ax5 ax6], 'FontSize', font_size);
set([ax4 ax5 ax6], 'TickLength', 0.005*[1 1]);
linkaxes([ax4 ax5 ax6], 'x');
% xlim(corr_scale);

%% Visualization #2: Show pairs of traces and their correlations

figure;
type = 'ctxstr';
sort_dir = 'descend'; % Shows HIGHEST correlated pairs
% sort_dir = 'ascend'; % Shows LOWEST correlated pairs

switch (type)
    case 'ctxstr'
        corrlist = sortrows(corr_to_corrlist(C_ctxstr), 3, sort_dir);
        get_trace1 = @(k,i) resampled_ctx_traces{k}(i,:); % i-th ctx cell on k-th trial
        get_trace2 = @(k,j) resampled_str_traces{k}(j,:); % i-th str cell on k-th trial
        get_ylabel = @(i,j,c) sprintf('Ctx = %d\nStr = %d\n\\rho = %.4f',...
            ctx_info.cell_ids_in_rec(i), str_info.cell_ids_in_rec(j), c); % Report cell #'s as in the rec file
        color1 = 'k';
        color2 = 'm';
        
    case 'ctx'
        corrlist = sortrows(corr_to_corrlist(C_ctx, 'upper'), 3, sort_dir);
        get_trace1 = @(k,i) resampled_ctx_traces{k}(i,:);
        get_trace2 = @(k,j) resampled_ctx_traces{k}(j,:);
        get_ylabel = @(i,j,c) sprintf('Ctx = %d\nCtx = %d\n\\rho = %.4f',...
            ctx_info.cell_ids_in_rec(i), ctx_info.cell_ids_in_rec(j), c);
        color1 = 'b';
        color2 = 'r';
        
    case 'str'
        corrlist = sortrows(corr_to_corrlist(C_str, 'upper'), 3, sort_dir);
        get_trace1 = @(k,i) resampled_str_traces{k}(i,:);
        get_trace2 = @(k,j) resampled_str_traces{k}(j,:);
        get_ylabel = @(i,j,c) sprintf('Str = %d\nStr = %d\n\\rho = %.4f',...
            str_info.cell_ids_in_rec(i), str_info.cell_ids_in_rec(j), c);
        color1 = [0 0.447 0.741];
        color2 = [0.85 0.325 0.098];
        
end

num_to_show = 8;
y_lims = [-0.15 1.15];
sp = @(m,n,p) subtightplot(m, n, p, [0.02 0.05], 0.04, 0.03); % Gap, Margin-X, Margin-Y

trial_start_times = [trials(trials_to_use).start_time];
t_lims = [trials(trials_to_use(1)).start_time trials(trials_to_use(end)).us_time];

for i = 1:num_to_show
    cell_idx1 = corrlist(i,1);
    cell_idx2 = corrlist(i,2);
    corr_val = corrlist(i,3);
    
    sp(num_to_show,1,i);
    hold on;
    for k = trials_to_use
        trial = trials(k);

        plot(common_time{k}, get_trace1(k, cell_idx1), 'Color', color1);
        plot(common_time{k}, get_trace2(k, cell_idx2), 'Color', color2);
        plot_vertical_lines([trial.start_time, trial.us_time], y_lims, 'b:');
        plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
    end
    hold off;
    ylim(y_lims);
    xlim(t_lims);      
    ylabel(get_ylabel(cell_idx1, cell_idx2, corr_val),...
           'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');

    zoom xon;
    set(gca, 'TickLength', [0.001 0]);
    set(gca, 'XTick', trial_start_times);
    set(gca, 'XTickLabel', trials_to_use);
    set(gca, 'YTick', [0 1]);
    if (i == 1)
        switch (sort_dir)
            case 'descend'
                title(sprintf('%s - HIGHEST-correlated %s pairs',...
                    dataset_name, upper(type)));
            case 'ascend'
                title(sprintf('%s - LOWEST-correlated %s pairs',...
                    dataset_name, upper(type)));
        end
        
    elseif (i == num_to_show)
        xlabel('Trial index');
    end
end