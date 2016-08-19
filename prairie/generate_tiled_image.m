function A = generate_tiled_image(XYZ, tiles, varargin)

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

% Determine the full image resolution
%------------------------------------------------------------
numPixels_x = size(tiles(1).im, 2);
numPixels_y = size(tiles(1).im, 1);

fov_x = micronsPerPixel_x * numPixels_x;
fov_y = micronsPerPixel_y * numPixels_y;

minX = min(XYZ(:,1));
maxX = max(XYZ(:,1)) + fov_x;
deltaX = maxX - minX;
numTotalPixels_x = ceil(deltaX / micronsPerPixel_x);

minY = min(XYZ(:,2));
maxY = max(XYZ(:,2)) + fov_y;
deltaY = maxY - minY;
numTotalPixels_y = ceil(deltaY / micronsPerPixel_y);

im_class = class(tiles(1).im);
A = zeros(numTotalPixels_y, numTotalPixels_x, im_class);

% Insert each tile into the full image
%------------------------------------------------------------
for k = 1:size(XYZ,1)
    % Compute the tile position in pixels
    px = floor((XYZ(k,1)-minX) / micronsPerPixel_x) + 1;
    py = floor((XYZ(k,2)-minY) / micronsPerPixel_y) + 1;
    
    A(py:(py+numPixels_y-1),...
      px:(px+numPixels_x-1)) = tiles(k).im;
end
