clear;

%% Concatenate trials
trial_indices = get_trial_frame_indices('distalopto.txt');
load('opto.mat'); % We use 'trial_inds'

num_frames_per_trial = trial_indices(:,end) - trial_indices(:,1) + 1;
num_trials = length(num_frames_per_trial);

num_total_frames = sum(num_frames_per_trial);
M = zeros(512, 512, num_total_frames, 'int16');

num_frames_saved = 0;
for k = 1:num_trials
    filename = sprintf('trial_%05d.tif', k);
    fprintf('%s: Loading "%s"...\n', datestr(now), filename);
    M_trial = load_scanimage_tif(filename);
    
    N = size(M_trial, 3);
    assert(N==num_frames_per_trial(k),...
        'Error! Number of frames in TIF file (%d) does not match that in trial table (%d)!',...
        N, num_frames_per_trial(k));
    
    % Process opto trials as necessary
    if isfield(trial_inds, 'real_alternate')
        if ismember(k, trial_inds.real_alternate)
            M_trial = dealternate_opto(M_trial);
            
            % Remove frames affected by IR soft shutter
            M_trial(:,:,2) = M_trial(:,:,3);
            M_trial(:,:,N-1) = M_trial(:,:,N-2);
        end
    end
    if isfield(trial_inds, 'real_interlace')
        if ismember(k, trial_inds.real_interlace)
            M_trial = deinterlace_opto_fpga(M_trial);
            M_trial(:,:,2) = M_trial(:,:,3);
            M_trial(:,:,N-1) = M_trial(:,:,N-2);
        end
    end
    
    % It appears that the first and last frames in each trial are often
    % dark (likely my IR "soft" shutter implementation for ITIs)
    M_trial(:,:,1) = M_trial(:,:,2);
    M_trial(:,:,N) = M_trial(:,:,N-1);

    % Concatenate
    M(:,:,trial_indices(k,1):trial_indices(k,end)) = M_trial;
end
fprintf('%s: Done!\n', datestr(now));

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