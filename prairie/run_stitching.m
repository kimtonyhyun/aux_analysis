clear all; close all;

xy_file = 'pos_160602-105921.xy';
XYZ = ReadPrairieXY(xy_file);

stitch_tiles(XYZ, pwd);