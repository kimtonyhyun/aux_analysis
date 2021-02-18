function Ms = rescale_movie(M, orig_clim, varargin)
% Scale movies to use a clim range of [0 1]. Other options to rescale the
% movie in space. Typically used for making side-by-side videos for 
% presentation purposes.

new_size = [NaN NaN];
for k = 1:length(varargin)
    if ischar(varargin{k})
        switch lower(varargin{k})
            case 'height'
                new_size(1) = varargin{k+1};
            case 'width'
                new_size(2) = varargin{k+1};
        end
    end
end

[h, w, num_frames] = size(M);
if all(isnan(new_size)) % No resizing requested
    new_size = [h, w];
else
    % Fill in missing dimension, if any
    A = imresize(M(:,:,1), new_size);
    new_size = size(A);   
end

% If the starting clim scale is not provided, compute it here
if ~exist('orig_clim', 'var')
    orig_clim = compute_movie_scale(M);
end

Ms = zeros(new_size(1), new_size(2), num_frames, 'single');

for k = 1:num_frames
    frame = M(:,:,k);
    frame = imresize(frame, new_size);
    frame = (frame - orig_clim(1)) / diff(orig_clim);
    
    % Bound pixel values to [0 1]
    frame = max(0, frame);
    frame = min(frame, 1);
    
    Ms(:,:,k) = frame;
end