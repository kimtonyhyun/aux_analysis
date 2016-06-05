function display_tiles(XYZ, tiles)
% Stitch tiled images from the Prairie. See 'run_stitch_tiles' for usage
% information.
%
% Inputs:
%   - XYZ: [num_tiles x 3] matrix containing the position of each tile
%   - tiles: Array of 'tile' structs. See 'load_prairie_tiles' for more
%            information
%

clim = [0 4096];

for i = 1:length(tiles)
    A = tiles(i).im;
    
    fov_x = size(A,2)*tiles(i).micronsPerPixel_x;
    fov_y = size(A,1)*tiles(i).micronsPerPixel_y;
    
    % Locate the image in global coordinate space by using the XYZ list
    RA = imref2d(size(A),...
                 XYZ(i,1) + [0 fov_x],...
                 XYZ(i,2) + [0 fov_y]);
    
    imshow(fliplr(A), RA, clim); hold on;
end

% Format the plot
axis image;
colormap gray;
xlabel('X [um]');
ylabel('Y [um]');
set(gca,'XDir','Reverse');