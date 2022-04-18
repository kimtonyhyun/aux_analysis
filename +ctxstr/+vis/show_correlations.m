function show_correlations(C_ctx, C_str, C_ctxstr, dataset_name, varargin)

data_type = 'r'; % r indicates Pearson correlation

for k = 1:length(varargin)
    if ischar(varargin{k})
        switch lower(varargin{k})
            case 'delta'
                data_type = '\Deltar';
        end
    end
end

[num_ctx_cells, num_str_cells] = size(C_ctxstr);

num_outliers_to_show = 10;
corr_scale = 0.5*[-1 1];
histogram_bins = linspace(-1, 1, 200); % Number of elements should be even, to properly capture 0
font_size = 18;

sp = @(m,n,p) subtightplot(m, n, p, 0.1, 0.03, 0.04); % Gap, Margin-X, Margin-Y

% figure;
sp(2,3,1);
imagesc(tril(C_ctx,-1), corr_scale);
colormap redblue;
axis image;
xlabel('Ctx neurons');
ylabel(sprintf('Ctx neurons (%d total)', num_ctx_cells));
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);
title(sprintf('%s: ctx-ctx %s', dataset_name, data_type));

sp(2,3,2);
imagesc(tril(C_str,-1), corr_scale);
axis image;
xlabel('Str neurons');
ylabel(sprintf('Str neurons (%d total)', num_str_cells));
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);
title(sprintf('str-str %s', data_type));

sp(2,3,3);
imagesc(C_ctxstr, corr_scale);
axis image;
xlabel('Str neurons');
ylabel('Ctx neurons');
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);
colorbar;
title(sprintf('ctx-str %s', data_type));

C_ctx_vals = C_ctx(tril(true(num_ctx_cells),-1));
C_str_vals = C_str(tril(true(num_str_cells),-1));
C_ctxstr_vals = C_ctxstr(:);

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
ylabel({sprintf('Ctx-ctx %s', data_type), 'counts'});
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
ylabel({sprintf('Str-str %s', data_type), 'counts'});
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
ylabel({sprintf('Ctx-str %s', data_type),  'counts'});
xlabel(data_type);
set(gca, 'YTickLabel', {});
set(gca, 'YTick', []);
set([ax4 ax5 ax6], 'FontSize', font_size);
set([ax4 ax5 ax6], 'TickLength', 0.005*[1 1]);
linkaxes([ax4 ax5 ax6], 'x');
% xlim(corr_scale);