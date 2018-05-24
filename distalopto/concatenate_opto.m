clear;

%% Concatenate trials
num_trials = 100;
frames_per_trial = 240;

M = zeros(512, 512, frames_per_trial*num_trials, 'int16');

for k = 1:num_trials
    filename = sprintf('trial_%05d.tif', k);
    fprintf('%s: Loading "%s"...\n', datestr(now), filename);
    M_trial = load_scanimage_tif(filename);
    
    start_idx = 1 + (k-1)*frames_per_trial;
    end_idx = start_idx + frames_per_trial - 1;
    M(:,:,start_idx:end_idx) = M_trial;
end

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