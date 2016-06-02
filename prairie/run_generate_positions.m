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
data_ap = [-1498.39 1501.95 -879.13;
           -1709.03 1501.95 -837.53;
           -1903.24 1501.95 -818.53;
           -2102.89 1501.95 -783.73;
           -2300.82 1501.95 -762.38;
           -2500.77 1501.95 -750.65;
           -2700.88 1501.95 -741.00;
           -2902.06 1501.95 -725.40;
           -3105.43 1501.95 -721.50;
           -3299.49 1501.95 -716.67;
           -3500.21 1501.95 -716.67;
          ];

% STEP 2: Acquire the profile along the ML axis (in YZ plane)
%------------------------------------------------------------
data_ml = [-1500.00 1301.54 -965.75;
           -1500.00 1100.50 -1056.08;
           -1500.00 902.57 -1139.03;
           -1499.32 698.74 -1238.75;
           -1498.39 499.88 -1369.65;
           -1498.39 301.79 -1522.15;
           -1498.39 100.90 -1748.75;
           -1498.39 1500.24 -878.60;
           -1498.39 1700.82 -794.73;
           -1498.39 1907.74 -707.92;
           -1498.39 2100.56 -656.53;
          ];
      
% STEP 3: Define the tiling boundary as a polygon
%------------------------------------------------------------
bounds = [-2000 3200 -1000;
          -2100 400 -1000;
          -3300 300 -1000;
          -3400 4000 -1000;
         ];

step_size = 300;
XYZ = generate_positions(data_ap, data_ml, bounds, step_size);

% Save XYZ positions to Prairie-readable file
timestamp = datestr(now, 'yymmdd-HHMMSS');
filename = sprintf('pos_%s.xy', timestamp);
WritePrarieXY(filename, XYZ);