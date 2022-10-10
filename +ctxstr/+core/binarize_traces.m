function [bin_traces, bin_traces_by_trial] = binarize_traces(traces, traces_by_trial, thresh)

num_cells = size(traces, 1);

max_amps = zeros(num_cells, 1);
for k = 1:num_cells
    max_amps(k) = max(traces(k,:));  
end

norm_fun = @(x) x ./ (max_amps*ones(1,size(x,2)));
bin_fun = @(x) double(x > thresh);

bin_traces = bin_fun(norm_fun(traces));

bin_traces_by_trial = cellfun(@(x) bin_fun(norm_fun(x)), traces_by_trial,...
    'UniformOutput', false);