%% Load all data into a single matrix

M = zeros(512,512,8000+600*100,'int16');

M_baseline = load_scanimage_tif('baseline_00001.tif');
M(:,:,1:8000) = M_baseline;

idx = 8001;
for k = 1:100
    fprintf('Loading Trial %d...\n', k);
    filename = sprintf('baseline_%05d.tif', k+1);
    M_trial = load_scanimage_tif(filename);
    M(:,:,idx:(idx+599)) = M_trial;
    idx = idx + 600;
end

clear filename idx k M_baseline M_trial;

%% Split into four separate movies

M1 = M(:,:,1:4:end);
M2 = M(:,:,2:4:end);
M3 = M(:,:,3:4:end);
M4 = M(:,:,4:4:end);

A1 = mean(M1,3);
A2 = mean(M2,3);
A3 = mean(M3,3);
A4 = mean(M4,3);

subplot(221); imagesc(A1); axis image; colormap gray; title('Slice 1');
subplot(222); imagesc(A2); axis image; title('Slice 2');
subplot(223); imagesc(A3); axis image; title('Slice 3');
subplot(224); imagesc(A4); axis image; title('Slice 4');

%% Save sub-movies to file
stem = 'm753-1020';

save_movie_to_hdf5(M1, sprintf('%s-sl1.hdf5', stem));
save_movie_to_hdf5(M2, sprintf('%s-sl2.hdf5', stem));
save_movie_to_hdf5(M3, sprintf('%s-sl3.hdf5', stem));
% save_movie_to_hdf5(M4, sprintf('%s-sl4.hdf5', stem));