clear all; close all;

% Tony Hyun Kim
% 2016 June 1
% Generate tiling positions for the curved coverslip
%
% ASSUMED ORIENTATION OF THE MOUSE RELATIVE TO THE PRAIRIE:
%   - Mouse head orientation (e.g. AP axis) is in the +x direction
%   - Mouse ML axis is in the +y direction

% STEP 1: Acquire the profile along the AP axis (in XZ plane)
%------------------------------------------------------------
data_ap = [
            2122.10 -5584.96 -4268.48;
            1582.70 -5584.96 -4272.88;
            502.98  -5584.96 -4288.33;
            -467.17 -5810.33 -4299.08;
            -1406.16 -5810.33 -4296.38;
            -2110.64 -5810.33 -4235.50;
          ];

% STEP 2: Acquire the profile along the ML axis (in YZ plane)
%------------------------------------------------------------
data_ml = [
            153.92 -2544.32 -5044.75;
            153.92 -2824.41 -4931.83;
            156.24 -3506.56 -4749.05;
            304.27 -4506.78 -4457.25;
            515.38 -5593.02 -4294.05;
            410.29 -5954.54 -4284.98;
            303.49 -6717.00 -4270.63;
            302.71 -7663.82 -4281.38;
            302.71 -8339.78 -4414.70;
            302.71 -8725.57 -4473.38;
            302.71 -9167.94 -4586.02;
            304.27 -9386.49 -4641.85;
   
          ];
      
% STEP 3: Define the tiling boundary as a polygon
%------------------------------------------------------------
bounds = [
            -2000 -9300;
            -2000 -2500;
             2000 -2500;
             2000 -9300;
         ];

step_size = 300;
XYZ = generate_positions(data_ap, data_ml, bounds, step_size);

% Save XYZ positions to Prairie-readable file
timestamp = datestr(now, 'yymmdd-HHMMSS');
filename = sprintf('pos_%s.xy', timestamp);
WritePrairieXY(filename, XYZ);