function data = import(behavior, dlc_filename, varargin)
% Convert the output of DeepLabCut (DLC) into a format that is more 
% readily usable in Matlab.

% Default parameters:
% - Median filtering window of 1 is equivalent to no filtering
medfilt_window = 1;

for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'medfilt'
                medfilt_window = varargin{k+1};
        end
    end
end

% Import data
[~, ~, ext] = fileparts(dlc_filename);
switch lower(ext)
    case '.csv'
        % Skip the first three header rows
        data = csvread(dlc_filename, 3, 0);
        num_dlc_frames = size(data,1);
        fprintf('Found %d frames in DeepLabCut CSV output\n', num_dlc_frames);
        
        front_left = data(:,2:3); % [x y]
        front_right = data(:,5:6);
        hind_left = data(:,8:9);
        hind_right = data(:,11:12);
        nose = data(:,14:15);
        tail = data(:,17:18);
        
    case '.mat'
        data = load(dlc_filename);
        num_dlc_frames = length(data.FLX);
        fprintf('Found %d frames in DeepLabCut MAT output\n', num_dlc_frames);
        
        front_left = [data.FLX data.FLY];
        front_right = [data.FRX data.FRY];
        hind_left = [data.HLX data.HLY];
        hind_right = [data.HRX data.HRY];
        nose = [data.NX data.NY];
        tail = [data.TX data.TY];
end

% Sanity check against behavioral frame clock from Saleae
t = behavior.frame_times;
num_behavior_frames = length(t);
fprintf('Expected %d behavioral frames from Saleae log\n', num_behavior_frames);

if num_dlc_frames < num_behavior_frames
    num_missing_frames = num_behavior_frames - num_dlc_frames;
    if num_missing_frames == 1
        cprintf('blue', 'Found one fewer DLC frame than expected. Most likely spurious behavior frame clock at end.\n');
        
        num_behavior_frames = num_behavior_frames - 1;
        t = t(1:end-1);
    else
        error('Found %d fewer DLC frames than expected!', num_missing_frames);
    end
elseif num_dlc_frames > num_behavior_frames
    cprintf('blue', 'There are more DLC frames than recorded by Saleae. Taking first %d frames only.\n', num_behavior_frames);
end

inds = 1:num_behavior_frames;
front_left = front_left(inds,:);
front_right = front_right(inds,:);
hind_left = hind_left(inds,:);
hind_right = hind_right(inds,:);
nose = nose(inds,:);
tail = tail(inds,:);

% (Optional) Apply median filter
if medfilt_window == 1
    fprintf('No median filtering applied\n');
else
    fprintf('Median filtering window is %d\n', medfilt_window);
    front_left = medfilt1(front_left, medfilt_window);
    front_right = medfilt1(front_right, medfilt_window);
    hind_left = medfilt1(hind_left, medfilt_window);
    hind_right = medfilt1(hind_right, medfilt_window);
    nose = medfilt1(nose, medfilt_window);
    tail = medfilt1(tail, medfilt_window);
end

info.dlc_filename = dlc_filename;
info.medfilt_window = medfilt_window; %#ok<STRNU>

save('dlc.mat', 't', 'front_right', 'front_left', 'hind_right', 'hind_left', 'nose', 'tail', 'info');

% Visualize results
dlc = load('dlc.mat');
ctxstr.dlc.plot_coords(dlc);

end % import_dlc

