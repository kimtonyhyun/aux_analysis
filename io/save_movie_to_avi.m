function save_movie_to_avi(M, frame_rate)

switch class(M)
    case {'uint16'}
        scale = [0 0.9*max(M(:))];
    case {'single'}
%         scale = compute_movie_scale(M);
        scale = [-0.02 0.05];
end

writerObj = VideoWriter('out.avi', 'Uncompressed AVI');
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