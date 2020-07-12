function [non_spiking_inds, non_spiking_segments] = find_nonspiking_periods(t_spikes, t_opt)

% First, we find all spiking periods
is_spiking = zeros(size(t_opt));

num_spikes = length(t_spikes);

for k = 1:num_spikes
    t_spike = t_spikes(k);
    
    % The range [t1, t2] represents the vicinity of the spike
    t1 = t_spike - 1000; % ms; 1000 in Huang
    t2 = t_spike + 4000; % ms; 4000 in Huang
    
    i1 = find(t_opt > t1, 1, 'first');
    i2 = find(t_opt < t2, 1, 'last');
    
    is_spiking(i1:i2) = 1;
end

% Non-spiking periods need to be at least 1 s long
non_spiking_inds = find(~is_spiking);

non_spiking_segments = frame_list_to_segments(non_spiking_inds); 
non_spiking_segment_durations = non_spiking_segments(:,2) - non_spiking_segments(:,1) + 1;

dto = t_opt(2) - t_opt(1); % ms

duration_filter = (dto * non_spiking_segment_durations) > 1000; % 1000 in Huang
non_spiking_segments = non_spiking_segments(duration_filter,:);

non_spiking_inds = frame_segments_to_list(non_spiking_segments);