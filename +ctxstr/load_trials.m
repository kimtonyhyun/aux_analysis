function trial_data = load_trials(trial_padding)
% Load various behavioral data into a trial structure.
%   Requires: 
%     - Output of 'parse_saleae' (i.e. "ctxstr.mat")
%   Optionally reads in:
%     - Output of 'dlc.compute_skeleton' (i.e. "skeleton.mat")
%     - Output of 'analyze_motion' (i.e. "motion_*.mat")

% Default params
if ~exist('trial_padding', 'var')
    trial_padding = 1; % seconds. Visualize period before and after each trial
end

path_to_behavior = fullfile(pwd, 'ctxstr.mat');
bdata = load(path_to_behavior);
behavior = bdata.behavior;
fprintf('Loaded behavioral data from "%s"\n', path_to_behavior);

path_to_skeleton = get_most_recent_file(pwd, 'skeleton.mat');
if ~isempty(path_to_skeleton)
    sdata = load(path_to_skeleton);
    fprintf('Loaded skeleton (DLC) data from "%s"\n', path_to_skeleton);
else
    sdata = [];
end

path_to_motion = get_most_recent_file(pwd, 'motion_*.mat');
if ~isempty(path_to_motion)
    mdata = load(path_to_motion);
    fprintf('Loaded motion analysis data from "%s"\n', path_to_motion);
else
    mdata = [];
end

% Parse into trials. Note that 'position', 'velocity', 'dlc.t' have
% different time-bases.
%------------------------------------------------------------
num_trials = length(behavior.us_times);
trial_data = struct('ind', [],...
                    'times', [],...
                    'start_time', [],...
                    'us_time', [],...
                    'duration', [],...
                    'lick_response', false,...
                    'lick_times', [],...
                    'position', [],... % [t_p, pos]
                    'velocity', [],... % [t_v, vel]
                    'dlc', [],...
                    'opto', [],...
                    'motion', struct('onsets', []));
trial_data = repmat(trial_data, num_trials, 1);

for k = 1:num_trials
    trial_data(k).ind = k;
    trial_data(k).position = behavior.position.by_trial{k}; % Use prior trial parsing from 'parse_saleae'
    
    t_lims = trial_data(k).position([1 end],1) + trial_padding * [-1 1]';
    trial_data(k).times = t_lims; % Includes padding
    
    if k > 1
        trial_data(k).start_time = trial_data(k-1).us_time;
    else
        trial_data(k).start_time = trial_data(k).position(1,1);
    end
    trial_data(k).us_time = behavior.us_times(k);
    trial_data(k).duration = trial_data(k).us_time - trial_data(k).start_time;
    
    trial_data(k).lick_response = behavior.lick_responses(k);
    trial_data(k).lick_times = find_licks(behavior.lick_times, t_lims); % All licks in trial + padding
    
    inds = ctxstr.core.find_frames_by_time(behavior.velocity(:,1), t_lims);
    trial_data(k).velocity = behavior.velocity(inds, :);
    
    for m = 1:size(behavior.opto_periods,1)
        t = range_intersection(behavior.opto_periods(m,:), t_lims);
        if ~isempty(t)
            trial_data(k).opto = t;
        end
    end
    
    if ~isempty(sdata)
        inds = ctxstr.core.find_frames_by_time(sdata.t, t_lims);
        dlc_data.t = [sdata.t(inds) inds'];
        dlc_data.beta_f = sdata.beta_f(inds);
        dlc_data.beta_h = sdata.beta_h(inds);
        trial_data(k).dlc = dlc_data;
    end
    
    if ~isempty(mdata)
        trial_data(k).motion.onsets = mdata.onsets{k};
    end
end

end

function licks = find_licks(all_licks, tlims)
    inds = (tlims(1) <= all_licks) & (all_licks <= tlims(2));
    licks = all_licks(inds);
end