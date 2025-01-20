function [edges, inds] = find_edges(saleae_file, channel, find_neg)
% Return the timestamp of all rising edges on Saleae-generated log.
%
% Notes:
%   - Channel indexed from 0
%   - Assumes no header line in 'saleae_file'
%   - Set 'find_neg' == true to find falling edges
%   - Set 'find_neg' == 'all' to find both rising and falling edges
%   - Auxiliary output 'inds' can be used to check the values of other
%     signals in the Saleae log at edge times

if ~exist('find_neg', 'var')
    edge_fn = @(prev, curr) ~prev && curr;
elseif any(strcmp(find_neg, {'all', 'both'}))
    edge_fn = @(prev, curr) (~prev && curr) || (prev && ~curr);
else
    edge_fn = @(prev, curr) (prev && ~curr);
end

if isstring(saleae_file)
    data = csvread(saleae_file);
else
    data = saleae_file;
end
times = data(:,1);
trace = data(:,2+channel);

edges = zeros(size(times)); % Preallocate
inds = zeros(size(times));
num_edges = 0;

prev_val = trace(1);
for k = 2:length(trace)
    val = trace(k);
    if edge_fn(prev_val, val)
        num_edges = num_edges + 1;
        edges(num_edges) = times(k);
        inds(num_edges) = k;
    end
    prev_val = val;
end

edges = edges(1:num_edges);
inds = inds(1:num_edges);