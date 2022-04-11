%% Display formatting

sp = @(m,n,p) subtightplot(m, n, p, [0.02 0.05], 0.04, 0.03); % Gap, Margin-X, Margin-Y

num_rows_per_page = 8;
y_lims = [-0.15 1.15];
t_lims = [trials(trials_to_use(1)).start_time trials(trials_to_use(end)).us_time];
color1 = 'k';
color2 = 'm';
get_ylabel = @(i,j,c) sprintf('Ctx = %d\nStr = %d\n\\rho = %.4f',...
            ctx_info.cell_ids_in_rec(i), str_info.cell_ids_in_rec(j), c); % Report cell #'s as in the rec file

%% Order all possible pairs in decreasing order of Pearson correlations

corrlist = sortrows(corr_to_corrlist(C_ctxstr), 3, 'descend');

%% Best match for each CTX cell

corrlist = zeros(num_ctx_cells, 3);
for i = 1:num_ctx_cells
    corr_vals = C_ctxstr(i,:);
    [sorted_vals, sort_ind] = sort(corr_vals, 'descend');
    corrlist(i,:) = [i, sort_ind(1), sorted_vals(1)];
end
clear corr_vals sorted_vals sort_ind;

%% Best match for each STR cell

corrlist = zeros(num_str_cells, 3);
for j = 1:num_str_cells
    corr_vals = C_ctxstr(:,j);
    [sorted_vals, sort_ind] = sort(corr_vals, 'descend');
    corrlist(j,:) = [sort_ind(1), j, sorted_vals(1)];
end
clear corr_vals sorted_vals sort_ind;

%% All matches for one STR cell

str_idx = 12;
corrlist = [(1:num_ctx_cells)', str_idx*ones(num_ctx_cells,1), C_ctxstr(:,str_idx)];
corrlist = sortrows(corrlist, 3, 'descend');

%% Display

row_chunks = make_frame_chunks(size(corrlist,1), num_rows_per_page);
num_pages = size(row_chunks, 1);

for p = 1:num_pages
    rows = row_chunks(p,1):row_chunks(p,2);
    
    clf;
    for r = 1:length(rows)
        row = rows(r);
        ctx_idx = corrlist(row,1);
        str_idx = corrlist(row,2);
        corr_val = corrlist(row,3);
        
        sp(num_rows_per_page, 1, r);
        hold on;
        for k = trials_to_use
            trial = trials(k);

            plot(common_time{k}, resampled_ctx_traces{k}(ctx_idx,:), 'Color', color1);
            plot(common_time{k}, resampled_str_traces{k}(str_idx,:), 'Color', color2);
            plot_vertical_lines([trial.start_time, trial.us_time], y_lims, 'b:');
            plot_vertical_lines(trial.motion.onsets, y_lims, 'r:');
        end
        hold off;
        xlim(t_lims);
        ylim(y_lims);
        ylabel(get_ylabel(ctx_idx, str_idx, corr_val),...
               'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
           
        set(gca, 'TickLength', [0.001 0]);
        set(gca, 'XTick', [trials(trials_to_use).start_time]);
        set(gca, 'XTickLabel', trials_to_use);
        set(gca, 'YTick', [0 1]);
    end
    xlabel('Trials');
    fprintf('%s: Displaying page %d of %d... \n', datestr(now), p, num_pages);
    pause;
end