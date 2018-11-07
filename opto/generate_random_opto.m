function [trial_inds, laser_inds] = generate_random_opto(ds, N)
% One in N trials will be randomly assigned as an "opto" trial

num_trials = ds.num_trials;

% For each block of N trials, decide which trial is the opto trial
num_blocks = floor(num_trials/N);
opto_ind = randi(N, 1, num_blocks);

% Now, unpack into an absolute trial index
opto_trials = [];
for k = 1:num_blocks
    opto_trials = [opto_trials N*(k-1)+opto_ind(k)]; %#ok<AGROW>
end

trial_inds.real = opto_trials;
trial_inds.sham = [];
trial_inds.off = setdiff(1:num_trials, opto_trials);

laser_inds = convert_opto_trials_to_frames(trial_inds, ds.trial_indices);