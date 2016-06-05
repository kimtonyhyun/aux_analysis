function tiles = load_prairie_tiles(root_dir)
% Returns the individual tiles as a struct array. The fields are:
%   - name: Filename of the tif image
%   - im: Image
%   - fov_x, fov_y: Field of view in microns
%
% We assume that each image is contained in a subfolder of 'root_dir', with
% prefix 'SingleImage*'.

ds = dir(fullfile(root_dir, 'SingleImage*'));
num_tiles = length(ds);

tiles = repmat(struct('name', '', 'im', [], 'fov_x', [], 'fov_y', []),...
               num_tiles, 1);

for i = 1:num_tiles
    if (mod(i,100)==0)
        fprintf('  Loading tile %d of %d...\n', i, num_tiles);
    end

    % Each subdirectory is expected to contain an XML and TIF file
    sub_dir = fullfile(root_dir, ds(i).name);
    
    xml_file = dir(fullfile(sub_dir, '*.xml'));
    [~, p] = ReadPrairieXMLFile(fullfile(sub_dir, xml_file.name));
    
    tif_file = dir(fullfile(sub_dir, '*.tif'));
    tif_file = fullfile(sub_dir, tif_file.name);
    
    tiles(i).name = tif_file;
    tiles(i).im = imread(tif_file);
    tiles(i).fov_x = str2double(p.pixelsPerLine)*str2double(p.micronsPerPixel_XAxis);
    tiles(i).fov_y = str2double(p.linesPerFrame)*str2double(p.micronsPerPixel_YAxis);
end

end % load_prairie_tiles

