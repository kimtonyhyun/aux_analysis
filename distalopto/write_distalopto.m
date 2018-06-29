function write_distalopto(trial_frame_indices, trial_rewarded, trial_durations)
% Generate PlusMaze-like text file from the DistalOpto behavioral
% experiment. Trial correctness is encoded.

output_name = 'distalopto.txt';
fid = fopen(output_name, 'w');

num_trials = size(trial_frame_indices,1);
for i = 1:num_trials
    if trial_rewarded(i)
        trial_result = 'north';
    else
        trial_result = 'south';
    end
    fprintf(fid, '%s %s %s %.3f %d %d %d %d\n',...
        'east', 'north', trial_result,...
        trial_durations(i),...
        trial_frame_indices(i,1), trial_frame_indices(i,2),...
        trial_frame_indices(i,3), trial_frame_indices(i,4));
end
fclose(fid);