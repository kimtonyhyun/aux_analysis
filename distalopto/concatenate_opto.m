clear;

%% Concatenate trials
num_trials = 160;

% Preallocate
M = zeros(512, 512, 50000, 'int16');

num_frames_saved = 0;
for k = 1:num_trials
    filename = sprintf('trial_%05d.tif', k);
    fprintf('%s: Loading "%s"...\n', datestr(now), filename);
    M_trial = load_scanimage_tif(filename);
    
    start_idx = num_frames_saved + 1;
    end_idx = start_idx + size(M_trial,3) - 1;
    M(:,:,start_idx:end_idx) = M_trial;
    
    num_frames_saved = end_idx;
end
M = M(:,:,1:num_frames_saved);


%% Inspect fluorescence stats
F = compute_fluorescence_stats(M);
plot(F);
grid on;
xlim([1 size(M,3)]);
% ylim([-500 2000]);
xlabel('Frames');
ylabel('Fluorescence');

%% Subtract off min offset
M = M - int16(mean(F(:,1)));
fprintf('%s: Min offset corrected!\n', datestr(now));