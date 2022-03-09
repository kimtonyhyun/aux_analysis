function binned_indices = bin_frames_in_time(source, bin_factor)

frame_indices = get_trial_frame_indices(source);
binned_indices = ceil(frame_indices/bin_factor);

% Save to file
[~, name] = fileparts(source);
output_name = sprintf('%s_ti%d.txt', name, bin_factor);
overwrite_frame_indices(source, binned_indices, output_name);