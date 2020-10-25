function data = import(behavior, dlc_filename, varargin)
% Convert the CSV output of DeepLabCut (DLC) into a format that is more 
% readily usable in Matlab. The basic idea is to confirm that there are no
% noisy outliers in the DLC coordinates.

% Median filtering window of 1 is equivalent to no filtering
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

data = csvread(dlc_filename, 3, 0);
num_dlc_frames = size(data,1);
fprintf('Found %d frames in DeepLabCut output\n', num_dlc_frames);

% Behavioral frame clock from Saleae
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

if medfilt_window == 1
    fprintf('No median filtering applied\n');
else
    fprintf('Median filtering window is %d\n', medfilt_window);
end
inds = 1:num_behavior_frames;
front_left = medfilt1(data(inds,2:4), medfilt_window); % [x, y, likelihood]
front_right = medfilt1(data(inds,5:7), medfilt_window);
hind_left = medfilt1(data(inds,8:10), medfilt_window);
hind_right = medfilt1(data(inds,11:13), medfilt_window);
nose = medfilt1(data(inds,14:16), medfilt_window);
tail = medfilt1(data(inds,17:19), medfilt_window);

ax1 = subplot(6,2,1);
tight_plot(t, front_left(:,1));
ylabel('front left x');
ax2 = subplot(6,2,2);
tight_plot(t, front_left(:,2));
ylabel('front left y');

ax3 = subplot(6,2,3);
tight_plot(t, front_right(:,1));
ylabel('front right x');
ax4 = subplot(6,2,4);
tight_plot(t, front_right(:,2));
ylabel('front right y');

ax5 = subplot(6,2,5);
tight_plot(t, hind_left(:,1));
ylabel('hind left x');
ax6 = subplot(6,2,6);
tight_plot(t, hind_left(:,2));
ylabel('hind left y');

ax7 = subplot(6,2,7);
tight_plot(t, hind_right(:,1));
ylabel('hind right x');
ax8 = subplot(6,2,8);
tight_plot(t, hind_right(:,2));
ylabel('hind right y');

linkaxes([ax1 ax2 ax3 ax4 ax5 ax6 ax7 ax8], 'x');

subplot(6,2,9);
tight_plot(t, nose(:,1));
ylabel('nose x');
subplot(6,2,10);
tight_plot(t, nose(:,2));
ylabel('nose y');

subplot(6,2,11);
tight_plot(t, tail(:,1));
ylabel('tail x');
subplot(6,2,12);
tight_plot(t, tail(:,1));
ylabel('tail y');

info.dlc_filename = dlc_filename;
info.medfilt_window = medfilt_window;

save('dlc.mat', 't', 'front_right', 'front_left', 'hind_right', 'hind_left', 'nose', 'tail', 'info');

end % import_dlc

