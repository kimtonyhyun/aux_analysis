clear;

%% Read digital shutter data

trial_clk_ch = 1;

frame_times = find_edges('opto.csv', trial_clk_ch);
num_frames = length(frame_times);

%% Read analog modulation data

% Format: [Time(s) Mod(V)]. Both the nVoke and OBIS analog inputs use
% voltage range 0 to 5 V.
mod = csvread('mod.csv', 1, 0); % Skip first (header) line

% Sample modulation trace at the frame clock times
mod = interp1(mod(:,1), mod(:,2), frame_times);

mod_thresholds = [0.25 1 3];
num_levels = length(mod_thresholds);

laser_off = [];
laser_on = cell(num_levels, 1);

% Preprocess mod_thresholds
mod_thresholds = sort([mod_thresholds Inf]);

for k = 1:num_frames
    if mod(k) < mod_thresholds(1)
        laser_off = [laser_off k]; %#ok<*AGROW>
    else
        for m = 1:num_levels
            if mod(k) < mod_thresholds(m+1)
                lon = laser_on{m};
                lon = [lon k];
                laser_on{m} = lon;
                break;
            end
        end
    end
end
clear k m lon;


%%

% Save to file
save('opto.mat', 'laser_off', 'laser_on', 'num_levels');