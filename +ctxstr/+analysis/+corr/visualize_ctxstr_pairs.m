%% Order all CTX-STR pairs in decreasing order of Pearson correlations

corrlist = sortrows(corr_to_corrlist(C_ctxstr), 3, 'descend');

%% Best match for each CTX cell

corrlist = zeros(ctx_info.num_cells, 3);
for i = 1:ctx_info.num_cells
    corr_vals = C_ctxstr(i,:);
    [sorted_vals, sort_ind] = sort(corr_vals, 'descend');
    corrlist(i,:) = [i, sort_ind(1), sorted_vals(1)];
end
clear corr_vals sorted_vals sort_ind;

%% Best match for each STR cell

corrlist = zeros(str_info.num_cells, 3);
for j = 1:str_info.num_cells
    corr_vals = C_ctxstr(:,j);
    [sorted_vals, sort_ind] = sort(corr_vals, 'descend');
    corrlist(j,:) = [sort_ind(1), j, sorted_vals(1)];
end
clear corr_vals sorted_vals sort_ind;
corrlist = sortrows(corrlist, 3, 'descend');

%% All matches for one STR cell

num_ctx_cells = ctx_info.num_cells;
num_str_cells = str_info.num_cells;

str_idx = 30;
corrlist = [(1:num_ctx_cells)', str_idx*ones(num_ctx_cells,1), C_ctxstr(:,str_idx)];
corrlist = sortrows(corrlist, 3, 'descend');

%% Display

sp = @(m,n,p) subtightplot(m, n, p, [0.02 0.05], 0.04, [0.04 0.01]); % Gap, Margin-X, Margin-Y
color1 = 'k';
color2 = 'm';
get_ylabel = @(i,j,c) sprintf('Ctx = %d\nStr = %d\n{\\it r} = %.4f',...
            ctx_info.ind2rec(i), str_info.ind2rec(j), c); % Report cell #'s as in the rec file

num_rows_per_page = 8;
row_chunks = make_frame_chunks(size(corrlist,1), num_rows_per_page);
num_pages = size(row_chunks, 1);

figure;
for p = 1:num_pages
    rows = row_chunks(p,1):row_chunks(p,2);
    
    clf;
    for r = 1:length(rows)
        row = rows(r);
        
        ctx_idx = corrlist(row,1);
        traces1 = ctxstr.core.get_traces_for_cell(ctx_idx, ctx_traces_by_trial);
        
        str_idx = corrlist(row,2);
        traces2 = ctxstr.core.get_traces_for_cell(str_idx, str_traces_by_trial);
        
        corr_val = corrlist(row,3);
        
        sp(num_rows_per_page, 1, r);
        ctxstr.vis.draw_traces(st_trial_inds, trials,...
            time_by_trial, traces1, traces2,...
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