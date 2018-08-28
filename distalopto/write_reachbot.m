function write_reachbot(trial_frame_indices)
% Generate PlusMaze-like text file from the ReachBot behavioral
% experiment.

output_name = 'reachbot.txt';
fid = fopen(output_name, 'w');

num_trials = size(trial_frame_indices,1);
for i = 1:num_trials
    fprintf(fid, '%s %s %s %.3f %d %d %d %d\n',...
        'east', 'north', 'north',...
        1.0,...
        trial_frame_indices(i,1), trial_frame_indices(i,2),...
        trial_frame_indices(i,3), trial_frame_indices(i,4));
end
fclose(fid);