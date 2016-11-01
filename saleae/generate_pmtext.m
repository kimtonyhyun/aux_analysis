function generate_pmtext(source)

num_frames = 2000;

[~, stem] = fileparts(source);
outname = sprintf('%s.txt', stem);
fid = fopen(outname, 'w');

trial_starts = find_trial_starts(source);
num_trials = length(trial_starts);

pm_filler = 'east north north 10.0';

trial_start = trial_starts(1,1);
if (trial_start ~= 1)
    fprintf(fid, '%s 1 1 1 %d\n', pm_filler, trial_start-1);
end

for k = 1:(num_trials-1)
    trial_start = trial_starts(k,1);
    led_on = trial_starts(k,2);
    reward_on = trial_starts(k,3);
    fprintf(fid, '%s %d %d %d %d\n', pm_filler,...
        trial_start, led_on, reward_on, trial_starts(k+1)-1);
end

trial_start = trial_starts(end,1);
fprintf(fid, '%s %d %d %d %d\n', pm_filler,...
    trial_start, trial_start, trial_start, num_frames);

fclose(fid);