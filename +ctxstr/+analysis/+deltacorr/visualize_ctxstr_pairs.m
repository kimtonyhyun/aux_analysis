%% Order all CTX-STR pairs in order of DELTA correlations

corrlist = sortrows(corr_to_corrlist(D_ctxstr), 3, 'ascend');

%% Sort by: TOP correlations on Day A

corrlist = sortrows(corr_to_corrlist(C_ctxstr_A), 3, 'descend');

%% Sort by: TOP correlations on Day B

corrlist = sortrows(corr_to_corrlist(C_ctxstr_B), 3, 'descend');

%% Display traces

% Below: Cell inds in corrlist refer only to the cells that matched across
% days. Thus, need to convert indices in order to properly access trace
% data on each day. We leave out the correlation value on days A and B to
% be later retrieved explicitly.
corrlist_A = [ctx_matched_inds(corrlist(:,1),1) str_matched_inds(corrlist(:,2),1)];
corrlist_B = [ctx_matched_inds(corrlist(:,1),2) str_matched_inds(corrlist(:,2),2)];

sp = @(m,n,p) subtightplot(m, n, p, [0.02 0.03], 0.04, [0.03 0.01]); % Gap, Margin-X, Margin-Y
color1 = 'k';
color2 = 'm';
get_ylabel_A = @(i,j,c) sprintf('Ctx = %d\nStr = %d\n{\\it r} = %.4f',...
            day_A.ctx_info.ind2rec(i), day_A.str_info.ind2rec(j), c);
get_ylabel_B = @(i,j,c) sprintf('Ctx = %d\nStr = %d\n{\\it r} = %.4f',...
            day_B.ctx_info.ind2rec(i), day_B.str_info.ind2rec(j), c);

num_rows_per_page = 8;
row_chunks = make_frame_chunks(size(corrlist,1), num_rows_per_page);
num_pages = size(row_chunks, 1);

figure;
for p = 1:num_pages
    rows = row_chunks(p,1):row_chunks(p,2);
    
    clf;
    for r = 1:length(rows)
        row = rows(r);

        % Day A
        %------------------------------------------------------------
        ctx_idx = corrlist_A(row,1);
        traces1 = ctxstr.core.get_traces_for_cell(ctx_idx, day_A.resampled_ctx_traces);

        str_idx = corrlist_A(row,2);
        traces2 = ctxstr.core.get_traces_for_cell(str_idx, day_A.resampled_str_traces);
        
        corr_val = day_A.C_ctxstr(ctx_idx, str_idx);
        
        sp(num_rows_per_page, 2, 2*r-1);
        ctxstr.vis.draw_traces(day_A.trials_for_corr, day_A.trials,...
            day_A.common_time, traces1, traces2,...
            color1, color2);
        ylabel(get_ylabel_A(ctx_idx, str_idx, corr_val),...
               'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
           
        if r == 1
            title(sprintf('%s: CTX-STR correlations', day_A.dataset_name));
        elseif r == num_rows_per_page % Last row
            xlabel('Trial index');
        end
        
        % Day B
        %------------------------------------------------------------
        ctx_idx = corrlist_B(row,1);
        traces1 = ctxstr.core.get_traces_for_cell(ctx_idx, day_B.resampled_ctx_traces);

        str_idx = corrlist_B(row,2);
        traces2 = ctxstr.core.get_traces_for_cell(str_idx, day_B.resampled_str_traces);
        
        corr_val = day_B.C_ctxstr(ctx_idx, str_idx);
        
        sp(num_rows_per_page, 2, 2*r);
        ctxstr.vis.draw_traces(day_B.trials_for_corr, day_B.trials,...
            day_B.common_time, traces1, traces2,...
            color1, color2);
        ylabel(get_ylabel_B(ctx_idx, str_idx, corr_val),...
               'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
           
        if r == 1
            title(sprintf('%s: CTX-STR correlations', day_B.dataset_name));
        elseif r == num_rows_per_page % Last row
            xlabel('Trial index');
        end
    end
    fprintf('%s: Displaying page %d of %d... \n', datestr(now), p, num_pages);
    pause;
end