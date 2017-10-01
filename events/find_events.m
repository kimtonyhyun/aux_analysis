function events = find_events(trace, threshold)
% Find segments of 'trace' above the specified 'threshold'. For each of
% these segments, return the maximum point as the associated event

above_thresh_frames = find(trace > threshold);
segments = frame_list_to_segments(above_thresh_frames);
num_segments = size(segments,1);

events = zeros(num_segments,1);
for k = 1:num_segments
    seg = segments(k,1):segments(k,2);
    tr_seg = trace(seg);
    [~, max_ind] = max(tr_seg);
    events(k) = seg(max_ind);
end