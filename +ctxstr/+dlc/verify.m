function verify(dlc_coord, behavior_vid)

num_coords = size(dlc_coord,1);

vid = VideoReader(behavior_vid);
A = vid.readFrame;

h_fig = figure;
h_im = image(A);
axis image;
truesize;
hold on;
h_coord = plot(dlc_coord(1,1), dlc_coord(1,2), 'r*');
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
        set(h_coord, 'XData', dlc_coord(k,1), 'YData', dlc_coord(k,2));
        title(sprintf('Frame %d of %d', k, num_coords));
    catch
        cprintf('blue', 'verify_dlc terminated by user\n');
        return;
    end
    drawnow;
end
