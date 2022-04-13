%% Display formatting

color1 = 'b';
color2 = 'r';
get_ylabel = @(i,j,c) sprintf('Str = %d\nStr = %d\n\\rho = %.4f',...
            ctx_info.cell_ids_in_rec(i), ctx_info.cell_ids_in_rec(j), c);

%% Order all possible pairs in decreasing order of Pearson correlations

corrlist = sortrows(corr_to_corrlist(C_ctx, 'upper'), 3, 'descend');

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
        
        ctx1_idx = corrlist(row,1);
        traces1 = ctxstr.core.get_traces_for_cell(ctx1_idx, resampled_ctx_traces);
        
        ctx2_idx = corrlist(row,2);
        traces2 = ctxstr.core.get_traces_for_cell(ctx2_idx, resampled_ctx_traces);
        
        corr_val = corrlist(row,3);
        
        sp(num_rows_per_page, 1, r);
        ctxstr.vis.draw_traces(trials_to_use, trials,...
            common_time, traces1, traces2,...
            color1, color2);
        ylabel(get_ylabel(ctx1_idx, ctx2_idx, corr_val),...
               'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
           
        if r == 1
            title(sprintf('%s: CTX-CTX correlations', dataset_name));
        elseif r == num_rows_per_page % Last row
            xlabel('Trial index');
        end
    end
    fprintf('%s: Displaying page %d of %d... \n', datestr(now), p, num_pages);
    pause;
end