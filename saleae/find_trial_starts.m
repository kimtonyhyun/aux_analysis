function trial_start_frames = find_trial_starts(saleae_file)
% Using a digital trace of the frame clock and trial clock in a Saleae CSV
% log, compute the frame numbers of the beginning of each trial.
%
% Notes:
%   - Assumes frame clock trace is in 2nd column
%   - Assumes trial clock trace is in 3rd column
%   - Assumes no header line in 'saleae_file'
%

data = csvread(saleae_file);
num_samples = size(data,1);

frame_clk = data(:,2);
trial_clk = data(:,3);

trial_start_frames = zeros(100,1); % Preallocate

frame_counter = 0;
trial_counter = 0;
for k = 2:num_samples
    if ~frame_clk(k-1) && frame_clk(k) %% Rising edge
        frame_counter = frame_counter + 1;
    end
    
    if ~trial_clk(k-1) && trial_clk(k)
        trial_counter = trial_counter + 1;
        trial_start_frames(trial_counter) = frame_counter;
    end
end
fprintf('%s: Found %d frames and %d trials\n',...
    saleae_file, frame_counter, trial_counter);
trial_start_frames = trial_start_frames(1:trial_counter);