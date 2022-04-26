function has_event = assign_events_to_frames(event_times, frame_times)
% For each event that occurs between the k-th and (k+1)-th frame, assign
% the event to either has_event(k) or has_event(k+1), depending on
% whichever is closer in time.
%
% See also 'assign_edges_to_frames.m'.

num_events = length(event_times);
num_frames = length(frame_times);
has_event = false(1, num_frames);

% First edge that takes place after the time of the first frame
first_assigned_event = find(event_times > frame_times(1), 1);

event_idx = first_assigned_event;
event_time = event_times(event_idx);
for k = 1:num_frames-1
    if (event_time < frame_times(k+1)) % event_time is between frame_times(k) and frame_times(k+1)

        % Determine whether the k-th or (k+1)-th frame is closer in time
        if abs(event_time - frame_times(k)) < abs(event_time - frame_times(k+1))
            has_event(k) = true;
        else
            has_event(k+1) = true;
        end
        
        % Move on to next event
        if (event_idx < num_events)
            event_idx = event_idx + 1;
            event_time = event_times(event_idx);
        else
            break;
        end
    end
end