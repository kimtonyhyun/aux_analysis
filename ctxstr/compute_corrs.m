% Trials only

clear all; close all;

ds_ctx = DaySummary('str.txt', 'ctx/union/resampled');
ds_str = DaySummary('str.txt', 'str/union/resampled');

%% Full traces

clear all; close all;

ds_ctx = DaySummary('', 'ctx/union/resampled');
ds_str = DaySummary('', 'str/union/resampled');

%% Compute correlations

num_ctx_cells = ds_ctx.num_classified_cells;
num_str_cells = ds_str.num_classified_cells;

num_ctx_pairs = num_ctx_cells * (num_ctx_cells-1) / 2;
ctx_corrs = zeros(num_ctx_pairs, 3); % Format: [Cell_i Cell_j Corr(i,j)]
idx = 1;
for i = 1:num_ctx_cells-1
    tr_i = ds_ctx.get_trace(i)';
    for j = i+1:num_ctx_cells
        tr_j = ds_ctx.get_trace(j)';
        ctx_corrs(idx,:) = [i, j, corr(tr_i, tr_j)];
        idx = idx + 1;
    end
end
ctx_corrs = sortrows(ctx_corrs, 3, 'descend');

num_str_pairs = num_str_cells * (num_str_cells-1) / 2;
str_corrs = zeros(num_str_pairs, 3);
idx = 1;
for i = 1:num_str_cells-1
    tr_i = ds_str.get_trace(i)';
    for j = i+1:num_str_cells
        tr_j = ds_str.get_trace(j)';
        str_corrs(idx,:) = [i, j, corr(tr_i, tr_j)];
        idx = idx + 1;
    end
end
str_corrs = sortrows(str_corrs, 3, 'descend');

num_ctxstr_pairs = num_ctx_cells * num_str_cells;
ctxstr_corrs = zeros(num_ctxstr_pairs, 3);
idx = 1;
for i = 1:num_ctx_cells
    tr_i = ds_ctx.get_trace(i)';
    for j = 1:num_str_cells
        tr_j = ds_str.get_trace(j)';
        ctxstr_corrs(idx,:) = [i, j, corr(tr_i, tr_j)];
        idx = idx + 1;
    end
end
ctxstr_corrs = sortrows(ctxstr_corrs, 3, 'descend');

clear i j idx;

%% View correlated Ctx-Str pairs

offset = -100;
for k = 1:num_ctxstr_pairs
    i = ctxstr_corrs(k,1);
    j = ctxstr_corrs(k,2);
    c = ctxstr_corrs(k,3);
    plot(ds_ctx.get_trace(i), 'b');
    hold on;
    plot(ds_str.get_trace(j)+offset, 'r');
    hold off;
    title(sprintf('Ctx=%d, Str=%d, Corr = %.4f', i, j, c));
    pause;
end

%% View correlated Str-Str pairs

offset = -100;
for k = 1:num_str_pairs
    i = str_corrs(k,1);
    j = str_corrs(k,2);
    c = str_corrs(k,3);
    plot(ds_str.get_trace(i), 'b');
    hold on;
    plot(ds_str.get_trace(j)+offset, 'r');
    hold off;
    title(sprintf('Str=%d, Str=%d, Corr = %.4f', i, j, c));
    pause;
end

%% View correlated Ctx-Ctx pairs

offset = -100;
for k = 1:num_ctx_pairs
    i = ctx_corrs(k,1);
    j = ctx_corrs(k,2);
    c = ctx_corrs(k,3);
    plot(ds_ctx.get_trace(i), 'b');
    hold on;
    plot(ds_ctx.get_trace(j)+offset, 'r');
    hold off;
    title(sprintf('Ctx=%d, Ctx=%d, Corr = %.4f', i, j, c));
    pause;
end

