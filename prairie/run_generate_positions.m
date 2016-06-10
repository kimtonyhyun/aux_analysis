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
            5124.77 -4878.63 -4655.05;
            3191.92 -4989.14 -4460.50;
            2355.07 -4456.41 -4522.75;
            1355.32 -4451.44 -4469.85;
            278.07 -4450.36 -4336.45;
            -110.98 -4406.96 -4353.73;
          ];

% STEP 2: Acquire the profile along the ML axis (in YZ plane)
%------------------------------------------------------------
data_ml = [
            
            2147.22 -3101.55 -4814.43;
            2146.75 -3263.37 -4766.08;
            2151.25 -3688.07 -4680.20;
            2151.25 -4544.29 -4485.65;
            2107.07 -4969.61 -4429.05;
            2107.69 -6036.94 -4362.50;
            2107.69 -6499.77 -4419.25;
            2107.23 -7443.88 -4549.95;
            2107.23 -8171.91 -4702.93;
            2109.71 -8901.19 -4881.68;
            2109.24 -9209.48 -4935.27;
            
          ];
      
% STEP 3: Define the tiling boundary as a polygon
%------------------------------------------------------------
left = 5000;
right = -100;
top = -3200;
bottom = -1500;

bounds = [
            left top;
            right top;
            right bottom;
            left bottom;
         ];

step_size = 300;
XYZ = generate_positions(data_ap, data_ml, bounds, step_size);

% Save XYZ positions to Prairie-readable file
timestamp = datestr(now, 'yymmdd-HHMMSS');
filename = sprintf('pos_%s.xy', timestamp);
WritePrairieXY(filename, XYZ);