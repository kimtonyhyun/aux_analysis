function parse_optotrials(csv_source)

% Returns LOGICAL trial indices for the different trial types
trials = find_opto_trials(csv_source);

% Convert to trial indices
trial_inds.real = find(trials.real);
trial_inds.sham = find(trials.sham);
trial_inds.off = find(trials.off);

% Convert to logical FRAME inds
frames_in_trial = true(1, 240); % Length is the number of frames per trial
laser.real = kron(trials.real, frames_in_trial);
laser.sham = kron(trials.sham, frames_in_trial);
laser.off = kron(trials.off, frames_in_trial);

% Convert to frame indices
laser_inds.real = find(laser.real);
laser_inds.sham = find(laser.sham);
laser_inds.off = find(laser.off);

% Save to file
save('opto.mat', 'laser_inds', 'trial_inds');