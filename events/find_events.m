function events = find_events(trace, threshold)
% Find segments of 'trace' above the specified 'threshold'. For each of
% these segments, return the maximum point as the associated event

above_thresh_frames = find(trace > threshold);
segments = frame_list_to_segments(above_thresh_frames);
num_segments = size(segments,1);

events = cell(1,num_segments);
for k = 1:num_segments
    seg = segments(k,1):segments(k,2);
    tr_seg = trace(seg);
    
%     events{k} = find_max(seg, tr_seg);
    events{k} = find_all_localmax(seg, tr_seg);
end
events = cell2mat(events);

end % find_events

function event = find_max(seg, tr_seg)
    [~, max_ind] = max(tr_seg);
    event = seg(max_ind);
end % find_max

function events = find_all_localmax(seg, tr_seg)
    x1 = [false tr_seg(2:end)>tr_seg(1:end-1)];
    x2 = [tr_seg(1:end-1)>tr_seg(2:end) false];

    events = seg(x1 & x2);
end % find_all_localmax