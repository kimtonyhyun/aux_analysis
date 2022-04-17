%% Order all STR-STR pairs in decreasing order of Pearson correlations

corrlist = sortrows(corr_to_corrlist(C_str, 'upper'), 3, 'descend');

%% All matches for one STR cell

str_idx = 30;
corrlist = [str_idx*ones(num_str_cells,1), (1:num_str_cells)', C_str(:,str_idx)];
corrlist = sortrows(corrlist, 3, 'descend');
corrlist = corrlist(2:end,:); % The top entry will be the cell itself

%% Display

sp = @(m,n,p) subtightplot(m, n, p, [0.02 0.05], 0.04, [0.04 0.01]); % Gap, Margin-X, Margin-Y
color1 = [0 0.447 0.741];
color2 = [0.85 0.325 0.098];
get_ylabel = @(i,j,c) sprintf('Str = %d\nStr = %d\n\\rho = %.4f',...
            str_info.ind2rec(i), str_info.ind2rec(j), c);
        
num_rows_per_page = 8;
row_chunks = make_frame_chunks(size(corrlist,1), num_rows_per_page);
num_pages = size(row_chunks, 1);

figure;
for p = 1:num_pages
    rows = row_chunks(p,1):row_chunks(p,2);
    
    clf;
    for r = 1:length(rows)
        row = rows(r);
        
        str1_idx = corrlist(row,1);
        traces1 = ctxstr.core.get_traces_for_cell(str1_idx, resampled_str_traces);
        
        str2_idx = corrlist(row,2);
        traces2 = ctxstr.core.get_traces_for_cell(str2_idx, resampled_str_traces);
        
        corr_val = corrlist(row,3);
        
        sp(num_rows_per_page, 1, r);
        ctxstr.vis.draw_traces(trials_to_use, trials,...
            common_time, traces1, traces2,...
            color1, color2);
        ylabel(get_ylabel(str1_idx, str2_idx, corr_val),...
               'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
           
        if r == 1
            title(sprintf('%s: STR-STR correlations', dataset_name));
        elseif r == num_rows_per_page % Last row
            xlabel('Trial index');
        end
    end
    fprintf('%s: Displaying page %d of %d... \n', datestr(now), p, num_pages);
    pause;
end