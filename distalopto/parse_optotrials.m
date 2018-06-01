clear;

%% Read digital shutter data

trial_clk_ch = 1;
real_shutter_ch = 0;
sham_shutter_ch = [];

[trial_inds, trial_times] = find_opto_trials('opto.csv', trial_clk_ch, real_shutter_ch, sham_shutter_ch);

%% Incorporate analog modulation data

% Format: [Time(s) Mod(V)]. Both the nVoke and OBIS analog inputs use
% voltage range 0 to 5 V.
mod = csvread('mod.csv', 1, 0); % Skip first (header) line

% Determine the analog modulation value for real opto trials, by sampling
% 1 second into the trial. Note: we are assuming that the trial is >1
% second long, and that the modulation value is held steady over the trial
opto_trial_inds = trial_inds.real;
opto_trial_times = trial_times(opto_trial_inds);
opto_mod_vals = interp1(mod(:,1), mod(:,2), opto_trial_times + 1);

% For now, we will assume that there are two power levels, and use the
% 'real' and 'sham' placeholders...
mod_threshold = 3;
high_power_trial_inds = opto_trial_inds(opto_mod_vals >= mod_threshold);
low_power_trial_inds = opto_trial_inds(opto_mod_vals < mod_threshold);

trial_inds.real = high_power_trial_inds;
trial_inds.sham = low_power_trial_inds;

%%

trial_frame_indices = get_trial_frame_indices('distalopto.txt');
laser_inds = convert_opto_trials_to_frames(trial_inds, trial_frame_indices); 

% Save to file
save('opto.mat', 'laser_inds', 'trial_inds');