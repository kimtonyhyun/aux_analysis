function verify(dlc, behavior_vid)

num_coords = length(dlc.t);

vid = VideoReader(behavior_vid);
A = vid.readFrame;

h_fig = figure;
h_im = image(A);
axis image;
truesize;
hold on;
h.front_left = plot(dlc.front_left(1,1), dlc.front_left(1,2), 'r*');
h.front_right = plot(dlc.front_right(1,1), dlc.front_right(1,2), 'r*');
h.hind_left = plot(dlc.hind_left(1,1), dlc.hind_left(1,2), 'r*');
h.hind_right = plot(dlc.hind_right(1,1), dlc.hind_right(1,2), 'r*');
h.nose = plot(dlc.nose(1,1), dlc.nose(1,2), 'r*');
h.tail = plot(dlc.tail(1,1), dlc.tail(1,2), 'r*');
hold off;

% Toolbar implementation in Matlab 2018b+ is broken
if ~verLessThan('matlab', '9.5')
    addToolbarExplorationButtons(h_fig);
    ax = gca;
    set(ax.Toolbar, 'Visible', 'off');
end

for k = 2:num_coords
    A = vid.readFrame;
    try
        set(h_im, 'CData', A);
        set(h.front_left, 'XData', dlc.front_left(k,1), 'YData', dlc.front_left(k,2));
        set(h.front_right, 'XData', dlc.front_right(k,1), 'YData', dlc.front_right(k,2));
        set(h.hind_left, 'XData', dlc.hind_left(k,1), 'YData', dlc.hind_left(k,2));
        set(h.hind_right, 'XData', dlc.hind_right(k,1), 'YData', dlc.hind_right(k,2));
        set(h.nose, 'XData', dlc.nose(k,1), 'YData', dlc.nose(k,2));
        set(h.tail, 'XData', dlc.tail(k,1), 'YData', dlc.tail(k,2));
        title(sprintf('Frame %d of %d', k, num_coords));
    catch
        cprintf('blue', 'verify_dlc terminated by user\n');
        return;
    end
    drawnow;
end
