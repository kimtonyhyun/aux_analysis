function t_spike = sample_nonspiking_interval(non_spiking_segments, t_opt)

num_segments = size(non_spiking_segments, 1);
num_frames_in_segment = non_spiking_segments(:,2) - non_spiking_segments(:,1) + 1;

dto = t_opt(2) - t_opt(1); % ms

% Need a buffer at the beginning and end of segments for DFF calculation
pre_buf = 20; % ms
post_buf = 50;
segment_durations = (dto * num_frames_in_segment) - pre_buf - post_buf;

p = segment_durations / sum(segment_durations);
seg_idx = randsample(num_segments, 1, true, p);

pre_buf_frames = ceil(pre_buf / dto);
post_buf_frames = ceil(post_buf / dto);
sample_idx = pre_buf_frames + randsample(num_frames_in_segment(seg_idx) - pre_buf_frames - post_buf_frames, 1);
sample_idx = (non_spiking_segments(seg_idx,1)-1) + sample_idx;

t_spike = t_opt(sample_idx);
