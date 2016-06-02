clear all; close all;

xy_file = 'merged3.xy';
XYZ = ReadPrairieXY(xy_file);

stitch_tiles(XYZ, pwd);