function cell_traces_by_trial = get_traces_for_cell(traces_by_trial, cell_idx)

cell_traces_by_trial = cellfun(@(x) x(cell_idx,:), traces_by_trial,...
                                'UniformOutput', false);