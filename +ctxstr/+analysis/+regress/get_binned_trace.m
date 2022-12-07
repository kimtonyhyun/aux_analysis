function binned_trace = get_binned_trace(reg, brain_area, cell_idx)

switch brain_area
    case 'ctx'
        binned_trace = reg.binned_ctx_traces(cell_idx,:);

    case 'str'
        binned_trace = reg.binned_str_traces(cell_idx,:);
end