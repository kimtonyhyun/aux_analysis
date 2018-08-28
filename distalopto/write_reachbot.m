function write_reachbot(trial_frame_indices, is_opto_trial)
% Generate PlusMaze-like text file from the ReachBot behavioral
% experiment. Opto is encoded in start location.

output_name = 'reachbot.txt';
fid = fopen(output_name, 'w');

num_trials = size(trial_frame_indices,1);
for i = 1:num_trials
    if ~is_opto_trial(i)
        startpos = 'west';
    else
        startpos = 'east';
    end
    fprintf(fid, '%s %s %s %.3f %d %d %d %d\n',...
        startpos, 'north', 'north',...
        1.0,...
        trial_frame_indices(i,1), trial_frame_indices(i,2),...
        trial_frame_indices(i,3), trial_frame_indices(i,4));
end
fclose(fid);