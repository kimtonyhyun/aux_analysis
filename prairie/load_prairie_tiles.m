function tiles = load_prairie_tiles(root_dir)
% Returns the individual tiles as a struct array. The fields are:
%   - name: Filename of the tif image
%   - im: Image
%   - micronsPerPixel_x, micronsPerPixel_y
%
% Note: We assume the FOV is identical for every tile!
%
% We assume that each image is contained in a subfolder of 'root_dir', with
% prefix 'SingleImage*'.

ds = dir(fullfile(root_dir, 'SingleImage*'));

% Sort directories by their acquisition order
acq_order = cellfun(@parse_acquisition_order, {ds.name}, 'UniformOutput', true);
[~, sort_idx] = sort(acq_order);
ds = ds(sort_idx);

num_tiles = length(ds);

tiles = repmat(struct('name', '', 'im', [], 'fov_x', [], 'fov_y', []),...
               num_tiles, 1);

for i = 1:num_tiles
    if (mod(i,100)==0)
        fprintf('  Loading tile %d of %d...\n', i, num_tiles);
    end

    % Each subdirectory is expected to contain an XML and TIF file
    sub_dir = fullfile(root_dir, ds(i).name);
    
    if (i==1)
        xml_file = dir(fullfile(sub_dir, '*.xml'));
        [~, p] = ReadPrairieXMLFile(fullfile(sub_dir, xml_file.name));
        micronsPerPixel_x = str2double(p.micronsPerPixel_XAxis);
        micronsPerPixel_y = str2double(p.micronsPerPixel_YAxis);
    end
    
    tif_file = dir(fullfile(sub_dir, '*.tif'));
    tif_file = fullfile(sub_dir, tif_file.name);
    
    tiles(i).name = tif_file;
    A = imread(tif_file);
    A = fliplr(A); % Note: LR reversal for proper tiling!
    tiles(i).im = A;
    tiles(i).micronsPerPixel_x = micronsPerPixel_x;
    tiles(i).micronsPerPixel_y = micronsPerPixel_y;
end

end % load_prairie_tiles

function acq_order = parse_acquisition_order(filename)
    % Assume format is 'SingleImage-06022016-1015-968', i.e. three numeric
    % fields where the last is the acquisition index
    p = sscanf(filename, 'SingleImage-%d-%d-%d');
    acq_order = p(3);
end % parse_acquisition_order