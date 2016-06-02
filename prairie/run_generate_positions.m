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
            4306.21 -5547.29 -1859.72;
            3527.49 -5283.02 -1838.25;
            2492.25 -5283.00 -1765.93;
            1483.20 -5283.02 -1689.97;
            661.70 -5284.10 -1623.58;
           -412.14 -5284.10 -1577.28;
           -1123.59 -5283.02 -1564.40;
          ];

% STEP 2: Acquire the profile along the ML axis (in YZ plane)
%------------------------------------------------------------
data_ml = [
            797.94 -2273.23 -2086.45;
            797.94 -2955.54 -1946.83;
            797.94 -4125.48 -1716.45;
            797.94 -4990.38 -1633.60;
            798.41 -6187.91 -1719.97;
            798.41 -6958.10 -1860.60;
            797.79 -7732.79 -2048.20;
            797.94 -8296.07 -2232.85;
            
          ];
      
% STEP 3: Define the tiling boundary as a polygon
%------------------------------------------------------------
bounds = [
            -500 -8000;
           -1500 -8000;
           -1500 -500;
            -500 -500;
         ];

step_size = 300;
XYZ = generate_positions(data_ap, data_ml, bounds, step_size);

% Save XYZ positions to Prairie-readable file
timestamp = datestr(now, 'yymmdd-HHMMSS');
filename = sprintf('pos_%s.xy', timestamp);
WritePrarieXY(filename, XYZ);