function data = import_dlc(dlc_filename)
% Convert the HDF5 output of DeepLabCut (DLC) into a format that is more 
% readily usable in Matlab

% Retrieve raw output from DLC. Each tracked point yields (X,Y,C) for each
% behavioral frame, where C is the confidence of DLC prediction (0 to 1).
data = h5read(dlc_filename, '/df_with_missing/table');
data = data.values_block_0;

% The behavior video captures animal movement from two vantage points, one
% from the "side" and the other from the "bottom". For each vantage point,
% we detect the following points:
%   Side: Eye, front-limb, hind-limb, tail (4 points total)
%   Bottom: Nose, 4 limbs, tail (6 points total)
%
% Thus, we can use the number of tracked points to determine whether the H5
% file corresponds to the Side vs. Bottom view

info.dlc_filename = dlc_filename;
info.num_frames = size(data,2);

switch size(data,1)
    case 12 % 4 tracked points * (X,Y,C)
        hindlimb = data(1:3,:)';
        forelimb = data(4:6,:)';
        eye = data(7:9,:)';
        tail = data(10:12,:)';
        
        save('dlc_side.mat', 'info',...
            'hindlimb', 'forelimb', 'eye', 'tail');
        
    case 18 % 6 tracked points * (X,Y,C)
        forelimb1 = data(1:3,:)';
        forelimb2 = data(4:6,:)';
        hindlimb1 = data(7:9,:)';
        hindlimb2 = data(10:12,:)';
        nose = data(13:15,:)';
        tail = data(16:18,:)';

        save('dlc_bottom.mat', 'info',...
            'nose', 'forelimb1', 'forelimb2', 'hindlimb1', 'hindlimb2', 'tail');
end