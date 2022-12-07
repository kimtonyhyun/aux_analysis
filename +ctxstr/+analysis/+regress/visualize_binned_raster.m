function visualize_binned_raster(reg, brain_area, cell_idx)
% Wrapper around 'show_aligned_binned_raster'.

binned_trace = ctxstr.analysis.regress.get_binned_trace(reg, brain_area, cell_idx);
ctxstr.vis.show_aligned_binned_raster(reg.st_trial_inds, reg.trials, binned_trace, reg.t);
title(sprintf('%s-%s, Cell %d', reg.dataset_name, brain_area, cell_idx));