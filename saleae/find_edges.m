function edges = find_edges(saleae_file, channel, find_neg)
% Return the timestamp of all rising edges on Saleae-generated log.
%
% Notes:
%   - Channel indexed from 0
%   - Assumes no header line in 'saleae_file'
%   - Set 'find_neg' == true to find falling edges
%
% TODO:
%   - Option for finding falling edges
%
if ~exist('find_neg', 'var')
    find_neg = false;
else
    find_neg = true;
end

if isstring(saleae_file)
    data = csvread(saleae_file);
else
    data = saleae_file;
end
times = data(:,1);
trace = data(:,2+channel);

edges = zeros(size(times)); % Preallocate
num_edges = 0;

prev_val = trace(1);
for k = 2:length(trace)
    val = trace(k);
    if ~find_neg % Find rising edges (default behavior)
        if (~prev_val && val)
            num_edges = num_edges + 1;
            edges(num_edges) = times(k);
        end    
    else % Find negative edges
        if (prev_val && ~val)
            num_edges = num_edges + 1;
            edges(num_edges) = times(k);
        end
    end
    prev_val = val;
end

edges = edges(1:num_edges);