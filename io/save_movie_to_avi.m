function save_movie_to_avi(M, scale)
% Save movie matrix into an uncompressed AVI file for presentation
% purposes. Consider compressing the output AVI file into MP4 using
% external software such as Handbrake.

% Default parameters:
frame_rate = 30; % Hz. Going below 30 Hz usually doesn't look good.

timestamp = datestr(now, 'yymmdd-HHMMSS');
output_name = sprintf('out_%s.avi', timestamp);

if ~exist('scale', 'var') % Scaling not provided
    switch class(M)
        case {'uint8'}
            scale = [0 255];
        case {'uint16'}
            scale = [0 0.9*max(M(:))];
        case {'single'}
            scale = compute_movie_scale(M);
    end
end

writerObj = VideoWriter(output_name, 'Uncompressed AVI');
writerObj.FrameRate = frame_rate;
open(writerObj);

h = imagesc(M(:,:,1), scale);
axis image;
truesize;
colormap gray;
set(gca, 'Visible', 'off');
for i = 1:size(M,3)
    set(h, 'CData', M(:,:,i));
    writeVideo(writerObj, getframe);
end
close(writerObj);