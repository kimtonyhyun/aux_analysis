function parse_optotrials(csv_source, trial_frame_indices)

% Returns LOGICAL trial indices for the different trial types
trials = find_opto_trials(csv_source);

trial_inds.real = find(trials.real);
trial_inds.sham = find(trials.sham);
trial_inds.off = find(trials.off);

% Convert trial-based opto information into FRAME basis
if isscalar(trial_frame_indices)
    % Easy case, where every trial has the same number of frames
    num_frames_per_trial = trial_frame_indices;
    
    frames_in_trial = true(1, num_frames_per_trial);
    laser.real = kron(trials.real, frames_in_trial);
    laser.sham = kron(trials.sham, frames_in_trial);
    laser.off = kron(trials.off, frames_in_trial);
else
    % Otherwise, we expect the number of frames in each trial to be
    % explicitly given
    num_frames = trial_frame_indices(end,end);
    real = false(1, num_frames);
    sham = false(1, num_frames);
    off = false(1, num_frames);
    
    num_trials = size(trial_frame_indices,1);
    for k = 1:num_trials
        trial_frames = trial_frame_indices(k,1):trial_frame_indices(k,end);
        if ismember(k, trial_inds.off)
            off(trial_frames) = true;
        elseif ismember(k, trial_inds.real)
            real(trial_frames) = true;
        elseif ismember(k, trial_inds.sham)
            sham(trial_frames) = true;
        end
    end
    
    laser.real = real;
    laser.sham = sham;
    laser.off = off;
end

% Convert to frame indices
laser_inds.real = find(laser.real);
laser_inds.sham = find(laser.sham);
laser_inds.off = find(laser.off);

% Save to file
save('opto.mat', 'laser_inds', 'trial_inds');