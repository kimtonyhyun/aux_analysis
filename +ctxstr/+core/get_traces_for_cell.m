function traces_j = get_traces_for_cell(j, traces)

traces_j = cell(size(traces));

for k = 1:length(traces)
    if ~isempty(traces{k})
        traces_j{k} = traces{k}(j,:);
    end
end