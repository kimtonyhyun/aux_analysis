function trial_data = load_trials(path_to_behavior, path_to_skeleton)
% Load various behavioral data into a trial structure. Requires:
%   - Output of 'parse_saleae' (i.e. "ctxstr.mat")
%   - Output of 'dlc.compute_skeleton' (i.e. "skeleton.mat")

% Defaults
%------------------------------------------------------------
trial_padding = 1; % seconds. Visualize period before and after each trial

if ~exist('path_to_behavior', 'var')
    path_to_behavior = 'ctxstr.mat';
end
bdata = load(path_to_behavior);
behavior = bdata.behavior;
fprintf('Loaded behavioral data from "%s"\n', path_to_behavior);

if ~exist('path_to_skeleton', 'var')
    path_to_skeleton = 'skeleton.mat';
end
sdata = load(path_to_skeleton);
fprintf('Loaded skeleton (DLC) data from "%s"\n', path_to_skeleton);

% Parse into trials. Note that 'position', 'velocity', 't_dlc' have
% different time-bases, as indicated in the comments below.
%------------------------------------------------------------
num_trials = length(behavior.us_times);
trial_data = struct('ind', [],...
                    'times', [],...
                    'start_time', [],...
                    'movement_onset_time', [],...
                    'us_time', [],...
                    'lick_times', [],...
                    'position', [],... % [t_p, pos]
                    'velocity', [],... % [t_v, vel]
                    't_dlc', [],... % [times(s) index-in-video-file]
                    'beta_f', [],... % [beta_f]
                    'beta_h', [],... % [beta_h]
                    'lick_response', false);
trial_data = repmat(trial_data, num_trials, 1);

for k = 1:num_trials
    trial_data(k).ind = k;
    
    trial_data(k).position = behavior.position.by_trial{k};
    trial_data(k).lick_response = behavior.lick_responses(k);
    trial_data(k).start_time = trial_data(k).position(1,1);
    trial_data(k).movement_onset_time = behavior.movement_onset_times(k);
    trial_data(k).us_time = behavior.us_times(k);
    
    t_lims = trial_data(k).position([1 end],1) + trial_padding * [-1 1]';
    trial_data(k).times = t_lims;
    
    trial_data(k).lick_times = find_licks(behavior.lick_times, t_lims);
    
    [ind1, ind2] = find_inds(behavior.velocity(:,1), t_lims);
    trial_data(k).velocity = behavior.velocity(ind1:ind2, :);
    
    [ind1, ind2] = find_inds(sdata.t, t_lims);
    trial_data(k).t_dlc = [sdata.t(ind1:ind2) (ind1:ind2)'];
    trial_data(k).beta_f = sdata.beta_f(ind1:ind2);
    trial_data(k).beta_h = sdata.beta_h(ind1:ind2);
end

end

function [ind1, ind2] = find_inds(t, tlims)
    ind1 = find(t >= tlims(1), 1, 'first');
    ind2 = find(t <= tlims(2), 1, 'last'); 
end

function licks = find_licks(all_licks, tlims)
    inds = (tlims(1) <= all_licks) & (all_licks <= tlims(2));
    licks = all_licks(inds);
end