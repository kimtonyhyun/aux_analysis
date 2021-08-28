function verify(behavior_vid, dlc, varargin)
% Example usage:
% >> dlc = load('dlc.mat');
% >> ctxstr.dlc.verify('oh21-10-22-down.mp4', dlc);

draw_lines = false;
for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case {'drawlines', 'draw_lines'}
                draw_lines = true;
        end
    end
end

if ~exist('dlc', 'var')
    dlc = load('dlc.mat');
end

num_coords = length(dlc.t);

vid = VideoReader(behavior_vid);
A = vid.readFrame;

h_fig = figure;
h_im = image(A);
axis image;
truesize;
hold on;

if draw_lines
    linespec = 'r*-';
else
    linespec = 'r*';
end
h.front = plot([dlc.front_left(1,1) dlc.front_right(1,1)],...
               [dlc.front_left(1,2) dlc.front_right(1,2)], linespec);
h.hind = plot([dlc.hind_left(1,1) dlc.hind_right(1,1)],...
              [dlc.hind_left(1,2) dlc.hind_right(1,2)], linespec);
h.body = plot([dlc.nose(1,1) dlc.tail(1,1)],...
              [dlc.nose(1,2) dlc.tail(1,2)], linespec);
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
        set(h.front, 'XData', [dlc.front_left(k,1) dlc.front_right(k,1)],...
                     'YData', [dlc.front_left(k,2) dlc.front_right(k,2)]);
        set(h.hind, 'XData', [dlc.hind_left(k,1) dlc.hind_right(k,1)],...
                    'YData', [dlc.hind_left(k,2) dlc.hind_right(k,2)]);
        set(h.body, 'XData', [dlc.nose(k,1) dlc.tail(k,1)],...
                    'YData', [dlc.nose(k,2) dlc.tail(k,2)]);
        title(sprintf('Frame %d of %d', k, num_coords));
    catch
        cprintf('blue', 'ctxstr.dlc.verify terminated by user\n');
        return;
    end
    drawnow;
end
