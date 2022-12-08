function visualize_binned_raster(reg, brain_area, cell_idx, varargin)
% Wrapper around 'show_aligned_binned_raster', to be used when visualizing
% a cell raster along with its regression result.

figure_name = [];
for k = 1:length(varargin)
    if ischar(varargin{k})
        vararg = lower(varargin{k});
        switch vararg
            case 'fig_name'
                figure_name = varargin{k+1};
        end
    end
end


binned_trace = ctxstr.analysis.regress.get_binned_trace(reg, brain_area, cell_idx);
ctxstr.vis.show_aligned_binned_raster(reg.st_trial_inds, reg.trials, binned_trace, reg.t);
title_str = sprintf('%s-%s, Cell %d', reg.dataset_name, brain_area, cell_idx);
title(title_str);

% Format figure name
hf = gcf;
if isempty(figure_name)
    hf.Name = title_str;
else
    hf.Name = figure_name;
end
hf.NumberTitle = 'off';