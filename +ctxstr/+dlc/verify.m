function verify(dlc_coord, behavior_vid)

num_coords = size(dlc_coord,1);

vid = VideoReader(behavior_vid);

A = vid.readFrame;
h_im = image(A);
truesize;
hold on;
h_coord = plot(dlc_coord(1,1), dlc_coord(1,2), 'r*');
hold off;

for k = 2:num_coords
    A = vid.readFrame;
    try
        set(h_im, 'CData', A);
        set(h_coord, 'XData', dlc_coord(k,1), 'YData', dlc_coord(k,2));
        title(sprintf('Frame %d of %d', k, num_coords));
    catch
        cprintf('blue', 'verify_dlc terminated by user\n');
        return;
    end
    drawnow;
end
