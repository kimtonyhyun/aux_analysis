function Ms = rescale_movie(M, orig_clim)
% Scale movies to use a clim range of [0 1]. Typically used for making
% side-by-side videos for demonstrations.

Ms = zeros(size(M), 'single');

for k = 1:size(M,3)
    frame = M(:,:,k);
    frame = (frame - orig_clim(1)) / diff(orig_clim);
    
    % Bound pixel values to [0 1]
    frame = max(0, frame);
    frame = min(frame, 1);
    
    Ms(:,:,k) = frame;
end