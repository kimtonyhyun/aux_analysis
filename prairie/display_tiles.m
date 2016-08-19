function display_tiles(XYZ, tiles, varargin)
% Stitch tiled images from the Prairie. See 'run_stitch_tiles' for usage
% information.
%
% Inputs:
%   - XYZ: [num_tiles x 3] matrix containing the position of each tile
%   - tiles: Array of 'tile' structs. See 'load_prairie_tiles' for more
%            information
%

micronsPerPixel_x = tiles(1).micronsPerPixel_x;
micronsPerPixel_y = tiles(1).micronsPerPixel_y;

for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'micronsperpixel' % Override scale present in XML
                micronsPerPixel_x = varargin{k+1};
                micronsPerPixel_y = varargin{k+1};
        end
    end
end

clim = [0 4096];

for i = 1:length(tiles)
    A = tiles(i).im;
    
    fov_x = size(A,2) * micronsPerPixel_x;
    fov_y = size(A,1) * micronsPerPixel_y;
    
    % Locate the image in global coordinate space by using the XYZ list
    RA = imref2d(size(A),...
                 XYZ(i,1) + [0 fov_x],...
                 XYZ(i,2) + [0 fov_y]);
    
    imshow(A, RA, clim); hold on;
end

% Format the plot
axis image;
colormap gray;
xlabel('X [um]');
ylabel('Y [um]');
set(gca, 'XDir', 'Reverse');