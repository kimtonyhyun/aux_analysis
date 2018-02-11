clear all; close all;

%% Load all data into a single matrix

% Expected number of frames:
%   - 8000 baseline frames prior to trials
%   - 600 frames per trial, 100 trials
M = zeros(512,512,8000+600*100,'int16');

M_baseline = load_scanimage_tif('baseline_00001.tif');
M(:,:,1:8000) = M_baseline;

idx = 8001;
for k = 1:100
    fprintf('Loading Trial %d...\n', k);
    filename = sprintf('trial_%05d.tif', k);
    M_trial = load_scanimage_tif(filename);
    M(:,:,idx:(idx+599)) = M_trial;
    idx = idx + 600;
end

clear filename idx k M_baseline M_trial;

%% Alternatively, load tdTomato data
M = load_scanimage_tif('tdt_00001.tif');

%% Inspect movie for abnormalities (i.e. saturated PMT)
F = compute_fluorescence_stats(M);
plot(F);
grid on;
xlim([1 size(M,3)]);
% ylim([-500 2000]);
xlabel('Frames');
ylabel('Fluorescence');

%% Subtract min offset
M = M - int16(mean(F(:,1)));

%% Examine the slices

A1 = mean(M(:,:,1:4:end),3);
A2 = mean(M(:,:,2:4:end),3);
A3 = mean(M(:,:,3:4:end),3);
A4 = mean(M(:,:,4:4:end),3);

figure;
subplot(221); imagesc(A1); axis image; colormap gray; title('Slice 1');
subplot(222); imagesc(A2); axis image; title('Slice 2');
subplot(223); imagesc(A3); axis image; title('Slice 3');
subplot(224); imagesc(A4); axis image; title('Slice 4');

%% Save sub-movies to file
stem = 'f761-0909-tdt';

% save_movie_to_hdf5(M(:,:,1:4:end), sprintf('%s-sl1.hdf5', stem));
save_movie_to_hdf5(M(:,:,2:4:end), sprintf('%s-sl2.hdf5', stem));
save_movie_to_hdf5(M(:,:,3:4:end), sprintf('%s-sl3.hdf5', stem));
save_movie_to_hdf5(M(:,:,4:4:end), sprintf('%s-sl4.hdf5', stem));