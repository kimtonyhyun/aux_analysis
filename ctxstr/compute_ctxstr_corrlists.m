function corrlists = compute_ctxstr_corrlists(ds_ctx, ds_str)
% Assumes that the traces of the two DaySummary's have been resampled so
% that they have the same time base.

ctx_cell_inds = find(ds_ctx.is_cell);
str_cell_inds = find(ds_str.is_cell);

ctx_traces = ds_ctx.get_trace(ctx_cell_inds)'; % [num_samples x num_cells]
str_traces = ds_str.get_trace(str_cell_inds)';

ctxstr_corrlist = corr_to_corrlist(corr(ctx_traces, str_traces));
ctxstr_corrlist(:,1) = ctx_cell_inds(ctxstr_corrlist(:,1)); % Convert to cell inds
ctxstr_corrlist(:,2) = str_cell_inds(ctxstr_corrlist(:,2));
ctxstr_corrlist = sortrows(ctxstr_corrlist, 3, 'descend');

ctx_corrlist = corr_to_corrlist(corr(ctx_traces), 'upper');
ctx_corrlist(:,1) = ctx_cell_inds(ctx_corrlist(:,1));
ctx_corrlist(:,2) = ctx_cell_inds(ctx_corrlist(:,2));
ctx_corrlist = sortrows(ctx_corrlist, 3, 'descend');

str_corrlist = corr_to_corrlist(corr(str_traces), 'upper');
str_corrlist(:,1) = str_cell_inds(str_corrlist(:,1));
str_corrlist(:,2) = str_cell_inds(str_corrlist(:,2));
str_corrlist = sortrows(str_corrlist, 3, 'descend');

% Package for output
corrlists.ctx = ctx_corrlist;
corrlists.str = str_corrlist;
corrlists.ctxstr = ctxstr_corrlist;