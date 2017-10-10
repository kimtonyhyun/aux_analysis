function events = find_events(trace, threshold)
% Find segments of 'trace' above the specified 'threshold'. Every local
% maximum within those segments are identified as events. This approach to
% event detection tends to work well with smoothed (e.g. low-pass filtered)
% versions of calcium traces.
%
% Returns:
%   events: [num_events x 3] where
%     events(k,1): Frame of the trough preceding the k-th event
%     events(k,2): Frame corresponding to the peak of the k-th event
%     events(k,3): Amplitude difference between peak and trough
%

if (nargin < 2)
    threshold = estimate_baseline_threshold(trace);
end

above_thresh_frames = find(trace >= threshold);

if ~any(above_thresh_frames)
    events = [];
    return;
end

segments = frame_list_to_segments(above_thresh_frames);
num_segments = size(segments,1);

eventpeaks = cell(1,num_segments);
for k = 1:num_segments
    seg = segments(k,1):segments(k,2);
    tr_seg = trace(seg);
    
    eventpeaks{k} = find_all_localmax(seg, tr_seg);
end
eventpeaks = cell2mat(eventpeaks);

% Format: [Trough-preceding-event Event-peak Event-amplitude]
num_events = length(eventpeaks);
events = zeros(num_events, 3);
for k = 1:num_events
    peak_frame = eventpeaks(k);
    trough_frame = seek_localmin(trace,peak_frame-1);
    event_amp = trace(peak_frame) - trace(trough_frame);
    
    events(k,:) = [trough_frame peak_frame event_amp];
end

% % Filter for amplitude heights (purposely very low threshold here)
% max_event_amplitude = max(events(:,3));
% filtered_events = events(:,3) > 0.05 * max_event_amplitude;
% events = events(filtered_events,:);

end % find_events

function events = find_all_localmax(seg, tr_seg)
    % Note that the first and last points of the segment cannot be
    % identified as a local maximum
    x1 = [false tr_seg(2:end)>tr_seg(1:end-1)];
    x2 = [tr_seg(1:end-1)>tr_seg(2:end) false];

    events = seg(x1 & x2);
end % find_all_localmax