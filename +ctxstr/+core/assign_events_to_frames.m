function has_event = assign_events_to_frames(event_times, frame_times)
% Compute a Boolean trace `has_events' with the same number of frames as
% `frame_times` where `has_event(k)` is 1 if there is an event that occurs
% between the start of the k-th and (k+1)-th frame.

num_events = length(event_times);
num_frames = length(frame_times);
has_event = false(num_frames, 1);

% First edge that takes place after the time of the first frame
first_assigned_event = find(event_times > frame_times(1), 1);

event_idx = first_assigned_event;
for k = 1:num_frames-1
    if (event_times(event_idx) < frame_times(k+1))
        has_event(k) = true;
        if (event_idx < num_events)
            event_idx = event_idx + 1;
        else
            break;
        end
    end
end