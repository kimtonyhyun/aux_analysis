function edges = find_edges(saleae_file, channel)
% Return the timestamp of all rising edges on Saleae-generated log.
%
% Notes:
%   - Channel indexed from 0
%   - Assumes no header line in 'saleae_file'
%
% TODO:
%   - Option for finding falling edges
%
data = csvread(saleae_file);
times = data(:,1);
trace = data(:,2+channel);

edges = zeros(size(times)); % Preallocate
num_edges = 0;

prev_val = trace(1);
for k = 2:length(trace)
    val = trace(k);
    if (~prev_val && val) % Rising edge
        num_edges = num_edges + 1;
        edges(num_edges) = times(k);
    end
    prev_val = val;
end

edges = edges(1:num_edges);