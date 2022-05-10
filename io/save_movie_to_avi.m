function save_movie_to_avi(M, varargin)
% Save movie matrix M into an uncompressed AVI file for presentation
% purposes. Consider compressing the output AVI file into MP4 using
% external software such as Handbrake.
%
% Movie M can be:
%   - Grayscale: [height x width x num_frames]
%   - RGB: [height x width x RGB x num_frames]

% Default parameters:
frame_rate = 30; % Hz. Going below 30 Hz usually doesn't look good.
movie_clim = [];
use_outline = 0;

for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'clim'
                movie_clim = varargin{k+1};
            case 'boundary'
                use_outline = 1;
                ds = varargin{k+1};
        end
    end
end

timestamp = datestr(now, 'yymmdd-HHMMSS');
output_name = sprintf('out_%s.avi', timestamp);

if isempty(movie_clim) % Scaling not provided
    switch class(M)
        case {'uint8'}
            movie_clim = [0 255];
        case {'uint16'}
            movie_clim = [0 0.9*max(M(:))];
        case {'single'}
            movie_clim = compute_movie_scale(M);
    end
end

writerObj = VideoWriter(output_name, 'Uncompressed AVI');
writerObj.FrameRate = frame_rate;
open(writerObj);

nd = ndims(M);
switch nd
    case 3 % [height x width x num_frames]       
        get_frame = @(k) M(:,:,k);
        h = imagesc(get_frame(1), movie_clim);
        colormap gray;
        if use_outline
            hold on;
            plot_boundaries(ds, 'Color', 'g');
        end

    case 4 % [height x width x RGB x num_frames]
        get_frame = @(k) M(:,:,:,k);
        h = image(get_frame(1));
end
num_frames = size(M,nd);

axis image;
truesize;
set(gca, 'Visible', 'off');
for k = 1:num_frames
    set(h, 'CData', get_frame(k));
    writeVideo(writerObj, getframe);
end
close(writerObj);