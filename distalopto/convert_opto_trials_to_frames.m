function frame_inds = convert_opto_trials_to_frames(trial_inds, trial_frame_indices)

types = fieldnames(trial_inds); % Trial types (e.g. 'off', 'real', 'sham', ...)
num_types = length(types);

num_trials = size(trial_frame_indices, 1);
num_frames = trial_frame_indices(end, end);

% Initialize
for j = 1:num_types
    frames.(types{j}) = false(1, num_frames);
end

for k = 1:num_trials
    trial_frames = trial_frame_indices(k,1):trial_frame_indices(k,end);
    for j = 1:num_types
        if ismember(k, trial_inds.(types{j}))
            % Admittedly, the syntax below is confusing...
            frames.(types{j})(trial_frames) = true;
        end
    end
end

% Convert to frame indices
for j = 1:num_types
    frame_inds.(types{j}) = find(frames.(types{j}));
end