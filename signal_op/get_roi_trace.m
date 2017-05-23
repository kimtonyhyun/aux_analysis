function trace = get_roi_trace(M)
% Retrieve a trace from a movie using binary ROI mask

A = mean(M,3);
imagesc(A); axis image; colormap gray;
roi = imellipse;
mask = createMask(roi);
mask_vec = 1/sum(mask(:)) * mask(:); % col

num_frames = size(M,3);
trace = zeros(num_frames,1);
for k = 1:num_frames
    frame = M(:,:,k);
    trace(k) = mask_vec' * frame(:);
end