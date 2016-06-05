clear all; close all;

xy_file = get_most_recent_file(pwd, '*.xy');
fprintf('Stitching images according to "%s"...\n', xy_file);
XYZ = ReadPrairieXY(xy_file);

tiles = load_prairie_tiles(pwd);

stitch_tiles(XYZ, tiles);