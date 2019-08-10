function has_edge = assign_edge_to_frames(edge_times, frame_times)
% Compute a Boolean trace `has_edge' with the same number of frames as
% `frame_times` where `has_edge(k)` is 1 if there is an edge that occurs
% between the start of the k-th and (k+1)-th frame.

num_edges = length(edge_times);
num_frames = length(frame_times);
has_edge = false(num_frames, 1);

% First edge that takes place after the time of the first frame
edge_idx = find(edge_times > frame_times(1), 1);

for k = 1:num_frames-1
    if (edge_times(edge_idx) < frame_times(k+1))
        has_edge(k) = true;
        if (edge_idx < num_edges)
            edge_idx = edge_idx + 1;
        else
            break;
        end
    end
end