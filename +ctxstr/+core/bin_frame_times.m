function t_binned = bin_frame_times(t, bin_factor)

num_orig_frames = length(t);
t_binned = mean(reshape(t, [bin_factor num_orig_frames/bin_factor]), 1);