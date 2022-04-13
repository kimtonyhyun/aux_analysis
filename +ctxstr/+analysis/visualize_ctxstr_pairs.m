%% Display formatting

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

sp = @(m,n,p) subtightplot(m, n, p, [0.02 0.05], 0.04, [0.04 0.01]); % Gap, Margin-X, Margin-Y

num_rows_per_page = 8;
row_chunks = make_frame_chunks(size(corrlist,1), num_rows_per_page);
num_pages = size(row_chunks, 1);

for p = 1:num_pages
    rows = row_chunks(p,1):row_chunks(p,2);
    
    clf;
    for r = 1:length(rows)
        row = rows(r);
        
        ctx_idx = corrlist(row,1);
        traces1 = ctxstr.core.get_traces_for_cell(ctx_idx, resampled_ctx_traces);
        
        str_idx = corrlist(row,2);
        traces2 = ctxstr.core.get_traces_for_cell(str_idx, resampled_str_traces);
        
        corr_val = corrlist(row,3);
        
        sp(num_rows_per_page, 1, r);
        ctxstr.vis.draw_traces(trials_to_use, trials,...
            common_time, traces1, traces2,...
            color1, color2);
        ylabel(get_ylabel(ctx_idx, str_idx, corr_val),...
               'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
           
        if r == 1
            title(sprintf('%s: CTX-STR correlations', dataset_name));
        elseif r == num_rows_per_page % Last row
            xlabel('Trial index');
        end
    end
    fprintf('%s: Displaying page %d of %d... \n', datestr(now), p, num_pages);
    pause;
end