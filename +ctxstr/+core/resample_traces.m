function resampled_data = resample_traces(data, t)

num_cells = size(data.traces, 1);
num_frames = length(t);

resampled_data.traces = zeros(num_cells, num_frames);
for k = 1:num_cells
    resampled_data.traces(k,:) = interp1(...
        data.t, data.traces(k,:), t, 'linear');
end

resampled_data.t = t;