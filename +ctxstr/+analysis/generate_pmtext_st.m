% This script will generate PlusMaze-style text files for ST trials in a
% CtxStr session

% clear all;

session = load('ctxstr.mat');
t_ctx = ctxstr.core.bin_frame_times(session.ctx.frame_times, 2); % 30 Hz --> 15 Hz
t_str = ctxstr.core.bin_frame_times(session.str.frame_times, 3); % 45 Hz --> 15 Hz

load('resampled_data.mat', 'trials', 'st_trial_inds');

f_ctx = fopen('ctx-st_15hz.txt', 'w');
f_str = fopen('str-st_15hz.txt', 'w');
pm_filler = 'east north north';

for k = st_trial_inds
    trial = trials(k);
    
    % One of the definitions of ST trials is that there is at least one
    % motion onset within the trial
    trial_times = [trial.start_time trial.motion.onsets(1) trial.us_time trial.us_time+1]; % s
    
    % Ctx
    trial_frames = assign_edge_to_frames(trial_times, t_ctx); % Boolean
    trial_frames = find(trial_frames);
    
    fprintf(f_ctx, '%s %.3f %d %d %d %d\n', pm_filler,...
        trial.duration, trial_frames(1), trial_frames(2), trial_frames(3), trial_frames(4));
    
    % Str
    trial_frames = assign_edge_to_frames(trial_times, t_str); % Boolean
    trial_frames = find(trial_frames);
    
    fprintf(f_str, '%s %.3f %d %d %d %d\n', pm_filler,...
        trial.duration, trial_frames(1), trial_frames(2), trial_frames(3), trial_frames(4));
end
fclose(f_ctx);
fclose(f_str);


