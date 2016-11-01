function trial_start_frames = find_trial_starts(saleae_file)
% Using a digital trace of the frame clock and trial clock in a Saleae CSV
% log, compute the frame numbers of the beginning of each trial.
%
% Notes:
%   - Assumes:
%       * frame clock trace is in 2nd column
%       * trial clock trace is in 3rd column
%       * LED enable on 4th column
%       * Reward valve on 5th column
%   - Assumes no header line in 'saleae_file'
%

data = csvread(saleae_file);
num_samples = size(data,1);

frame_clk = data(:,2);
trial_clk = data(:,3);
led_en = data(:,4);
reward_en = data(:,5);

% Preallocate output. Format: [trial-start led-start reward-start]
trial_start_frames = zeros(100,3);

frame_counter = 0;
trial_counter = 0;
led_detected_in_trial = 0; % Detect only the first LED edge per trial

for k = 2:num_samples
    if ~frame_clk(k-1) && frame_clk(k) %% Rising edge
        frame_counter = frame_counter + 1;
    end
    
    if ~trial_clk(k-1) && trial_clk(k)
        trial_counter = trial_counter + 1;
        trial_start_frames(trial_counter,1) = frame_counter;
        led_detected_in_trial = 0;
    end
    
    if (~led_en(k-1) && led_en(k)) && ~led_detected_in_trial
        trial_start_frames(trial_counter,2) = frame_counter;
        led_detected_in_trial = 1;
    end
    
    if ~reward_en(k-1) && reward_en(k)
        trial_start_frames(trial_counter,3) = frame_counter;
    end
end
fprintf('%s: Found %d frames and %d trials\n',...
    saleae_file, frame_counter, trial_counter);
trial_start_frames = trial_start_frames(1:trial_counter,:);