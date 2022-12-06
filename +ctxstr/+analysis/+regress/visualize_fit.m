function [brain_area, binned_trace] = visualize_fit(reg, brain_area, cell_idx, model_no, split_no)
% Wrapper around the 'plot_fit', in order to simplify the function call.
%
% FIXME: We return 'binned_trace' not because it's a conceptually relevant
% output of 'visualize_fit', but because in contexts where 'visualize_fit'
% is used, we often also utilize 'binned_trace'.

switch brain_area
    case {'ctx', 'c'}
        brain_area = 'ctx';
        trace_by_trial = ctxstr.core.get_traces_for_cell(reg.binned_ctx_traces_by_trial, cell_idx);
        binned_trace = reg.binned_ctx_traces(cell_idx,:);
        fd = reg.ctx_fit.data{cell_idx, model_no, split_no};

    case {'str', 's'}
        brain_area = 'str';
        trace_by_trial = ctxstr.core.get_traces_for_cell(reg.binned_str_traces_by_trial, cell_idx);
        binned_trace = reg.binned_str_traces(cell_idx,:);
        fd = reg.str_fit.data{cell_idx, model_no, split_no};
end

if isempty(fd)
    cprintf('red', 'Fit data for %s-%s, cell=%d is empty!\n', reg.dataset_name, brain_area, cell_idx);
else    
    ctxstr.analysis.regress.plot_fit(...
                    reg.time_by_trial, trace_by_trial, fd.train_trial_inds, fd.test_trial_inds,...
                    reg.models{model_no}, fd.kernels, fd.biases, fd.train_results, fd.test_results,...
                    reg.t, reg.reward_frames, reg.motion_frames, reg.velocity, reg.accel, reg.lick_rate);
    title(sprintf('%s-%s, Cell=%d, model #=%d, split #=%d',...
                reg.dataset_name, brain_area, cell_idx, model_no, split_no));
end