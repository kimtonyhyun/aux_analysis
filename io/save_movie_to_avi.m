function save_movie_to_avi(M, scale)
% Save movie matrix into an uncompressed AVI file for presentation
% purposes. Consider compressing the output AVI file into MP4 using
% external software such as Handbrake.

% Default parameters:
frame_rate = 30; % Hz. Going below 30 Hz usually doesn't look good.
output_name = 'out.avi';

if ~exist('scale', 'var') % Scaling not provided
    switch class(M)
        case {'uint16'}
            scale = [0 0.9*max(M(:))];
        case {'single'}
            scale = compute_movie_scale(M);
    end
end

writerObj = VideoWriter(output_name, 'Uncompressed AVI');
writerObj.FrameRate = frame_rate;
open(writerObj);
for i = 1:size(M,3)
    m = M(:,:,i);
    imagesc(m, scale);
    axis image;
    truesize;
    colormap gray;
    set(gca,'Visible','Off');
    writeVideo(writerObj, getframe);
end
close(writerObj);