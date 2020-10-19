function verify_dlc(dlc_coord, behavior_vid)

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
    set(h_im, 'CData', A);
    set(h_coord, 'XData', dlc_coord(k,1), 'YData', dlc_coord(k,2));
    drawnow;
end
