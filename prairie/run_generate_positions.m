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
            3722.02 -5675.02 -1307.65;
            3028.54 -5465.92 -1301.95;
            2086.15 -5465.92 -1228.72;
            1596.96 -5465.92 -1209.47;
            769.89 -5464.77 -1155.93;
           146.94 -5465.77 -1123.93;
           -571.02 -5465.77 -1094.30;
           -1114.76 -5465.77 -1070.56;
           
          ];

% STEP 2: Acquire the profile along the ML axis (in YZ plane)
%------------------------------------------------------------
data_ml = [
            1561.47 -2010.82 -1798.70;
            1561.47 -2814.18 -1581.30;
            1561.47 -3291.11 -1488.50;
            1561.47 -3740.61 -1412.45;
            1561.47 -4298.92 -1296.93;
            1557.13 -5675.02 -1216.70;
            1557.13 -6054.30 -1225.55;
            1557.13 -6645.47 -1281.13;
            1561.47 -7162.40 -1370.93;
            1561.47 -7562.76 -1467.28;
            1561.47 -8090.69 -1585.63;
          ];
      
% STEP 3: Define the tiling boundary as a polygon
%------------------------------------------------------------
bounds = [
            3000 -7500;
            -500 -7500;
            -500 -2500;
            3000 -2500;
         ];

step_size = 300;
XYZ = generate_positions(data_ap, data_ml, bounds, step_size);

% Save XYZ positions to Prairie-readable file
timestamp = datestr(now, 'yymmdd-HHMMSS');
filename = sprintf('pos_%s.xy', timestamp);
WritePrarieXY(filename, XYZ);