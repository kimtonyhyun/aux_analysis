clear;

%% Read digital shutter data

trial_clk_ch = 0;
real_shutter_ch = 1;
sham_shutter_ch = [];

[trial_inds, trial_times] = find_opto_trials('opto.csv', trial_clk_ch, real_shutter_ch, sham_shutter_ch);

%% Incorporate TEMPORAL modulation data

mode1_ch = 2;
mode0_ch = 3;

data = csvread('opto.csv');
mode1_vals = interp1(data(:,1), data(:,2+mode1_ch), trial_times + 0.1);
mode0_vals = interp1(data(:,1), data(:,2+mode0_ch), trial_times + 0.1);
mode_vals = 2*mode1_vals + mode0_vals; % Convert to decimal

trial_inds.real_postline = find(mode_vals==1);
trial_inds.real_interlace = find(mode_vals==2);
trial_inds.real_alternate = find(mode_vals==3);

fprintf('Temporal mod breakdown:\n');
fprintf('  - Postline: %d trials\n', length(trial_inds.real_postline));
fprintf('  - Interlace: %d trials\n', length(trial_inds.real_interlace));
fprintf('  - Alternate: %d trials\n', length(trial_inds.real_alternate));

%% Incorporate POWER modulation data

% Format: [Time(s) Mod(V)]. Both the nVoke and OBIS/Omicron analog inputs
% use voltage range 0 to 5 V.
mod = csvread('mod.csv', 1, 0); % Skip first (header) line

% Determine the analog modulation value for real opto trials, by sampling
% 1 second into the trial. Note: we are assuming that the trial is >1
% second long, and that the modulation value is held steady over the trial
opto_trial_inds = trial_inds.real;
opto_trial_times = trial_times(opto_trial_inds);
opto_mod_vals = interp1(mod(:,1), mod(:,2), opto_trial_times + 1);

% "Power Mod" scheme is that there are 3 power levels, corresponding to
% three different analog modulation voltage levels. Need to distinguish
% between them.
low = opto_trial_inds(opto_mod_vals < 0.5);
mid = opto_trial_inds(opto_mod_vals < 2);

% Don't double-count
high = setdiff(opto_trial_inds, mid);
mid = setdiff(mid, low);

trial_inds.real_low = low;
trial_inds.real_mid = mid;
trial_inds.real_high = high;

fprintf('Power mod breakdown:\n');
fprintf('  - Low: %d trials\n', length(low));
fprintf('  - Mid: %d trials\n', length(mid));
fprintf('  - High: %d trials\n', length(high));

%%

trial_frame_indices = get_trial_frame_indices('distalopto.txt');
laser_inds = convert_opto_trials_to_frames(trial_inds, trial_frame_indices); 

% Save to file
save('opto.mat', 'laser_inds', 'trial_inds');