function M = load_vlm_tif(stem)

files = dir(strcat(stem, '*'));
num_files = length(files);
num_frames_per_file = zeros(1, num_files);

% Scan the matching TIF files
for k = 1:num_files
    file = files(k).name;
    
    info = imfinfo(file);
    num_frames_per_file(k) = length(info);
    fprintf('File "%s" (%d of %d) has %d frames\n',...
            file, k, num_files, num_frames_per_file(k));
end
num_frames = sum(num_frames_per_file);
fprintf('  Total number of frames: %d\n', num_frames);

width = info(1).Width;
height = info(1).Height;

% Note: 1P VLM pixels are 16-bit unsigned integers
M = zeros(height, width, num_frames, 'uint16');

% Load frames into matrix
idx = 1;
for k = 1:num_files
    file = files(k).name;
    fprintf('Reading file "%s" (%d of %d)...\n', file, k, num_files);
    for i = 1:num_frames_per_file
        M(:,:,idx) = imread(file, i);
        idx = idx + 1;
    end
end