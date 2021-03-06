function track_body_duopus(vid_source, reward_source, varargin)
% Example usage: track_body_duopus('bottom0005.avi', 'rewards5.txt');

frame_halfwidth = 60; % Number of frames around the reward frame to analyze

preload_video = false;
coord_savename = '';
for k = 1:length(varargin)
    vararg = varargin{k};
    if (length(vararg) > 4) && strcmp(vararg(end-3:end), '.mat')
        coord_savename = vararg;
    else
        switch lower(vararg)
            case 'preload'
                preload_video = true;
        end
    end
end


if ~preload_video % Stream from file
    vid = VideoReader(vid_source);
    num_frames = vid.NumberOfFrames;
    height = vid.Height;
    width = vid.Width;
else
    M = load_behavior_video(vid_source);
    [height, width, num_frames] = size(M);
end

reward_frames = load(reward_source);
num_trials = length(reward_frames);

if isempty(coord_savename) % No intermediate save provided
    % Filename used in autosave
    timestamp = datestr(now, 'yymmdd-HHMMSS');
    coord_savename = sprintf('coords_%s.mat', timestamp);
    
    trials_to_analyze = 1:num_trials;
    coords = zeros(num_frames, 2); % Format: [x y]
else
    saved = load(coord_savename);
    
    assert(strcmp(vid_source, saved.vid_source),...
           'Video source in "%s" (%s) does not match provided video (%s)!',...
           coord_savename, saved.vid_source, vid_source);
    
    trials_complete = saved.t; % We save only completed trials
    fprintf('Resuming from Trial %d per "%s"...\n', trials_complete+1, coord_savename);
    
    trials_to_analyze = (trials_complete+1):num_trials;
    coords = saved.coords;
end

roi_halfwidth = 10; % Number of pixels to use for auto-track analysis
hist_spacing = 2.5;
hist_grid = 0:hist_spacing:50;

for t = trials_to_analyze
    fprintf('%s: Trial %d of %d...\n', datestr(now), t, num_trials);
    
    % Trial frames to track
    reward_frame = reward_frames(t);
    start_frame = max(1, reward_frame-frame_halfwidth);
    end_frame = min(num_frames, reward_frame+frame_halfwidth);
    
    f = start_frame;
    while (true)
        % Display frame
        %------------------------------------------------------------
%         subplot(3,3,[1 2 4 5 7 8]);
        current_frame = get_frame(f);
        imagesc(current_frame);
        axis image;
        xlabel('x');
        ylabel('y');
        title(sprintf('Frame %d (Trial %d: Frames %d to %d)',...
                      f, t, start_frame, end_frame));
        
        % Display existing coordinate, if it exists
        old_coord = coords(f,:);
        if coord_is_nonzero(old_coord)
            hold on;
            plot(old_coord(1), old_coord(2), 'o');
            hold off;
        end
        
        % If there is a previous coordinate, then show ROI (for
        % auto-tracking)
        if (f == 1)
            prev_coord = [0 0];
        else
            prev_coord = round(coords(f-1,:));
        end
        if coord_is_nonzero(prev_coord)
%             left = max(1, prev_coord(1)-roi_halfwidth);
%             right = min(width, prev_coord(1)+roi_halfwidth);
%             top = max(1, prev_coord(2)-roi_halfwidth);
%             bottom = min(height, prev_coord(2)+roi_halfwidth);
            
%             prev_frame = get_frame(f-1);
%             prev_sample = single(prev_frame(top:bottom, left:right, 1));
%             subplot(3,3,3);
%             imagesc(prev_sample, [0 255]);
%             colormap gray;
%             axis image;
%             hold on;
%             plot(roi_halfwidth+1, roi_halfwidth+1, 'r*');
%             hold off;
%             set(gca, 'XTickLabel', '', 'YTickLabel', '');
%             title(sprintf('Previous frame (%d)', f-1));
            
%             current_sample = single(current_frame(top:bottom, left:right, 1));
%             subplot(3,3,6);
%             imagesc(current_sample, [0 255]);
%             axis image;
%             set(gca, 'XTickLabel', '', 'YTickLabel', '');
%             title(sprintf('Current frame (%d)', f));
            
%             diff_sample = abs(current_sample - prev_sample);
%             diff_sample = diff_sample(:);
%             diff_score = round(prctile(diff_sample, 90));
%             subplot(3,3,9);
%             hist(diff_sample, hist_grid);
%             set(get(gca, 'child'), 'FaceColor', 0.3*[1 1 1]);
%             xlim([hist_grid(1) hist_grid(end)]+hist_spacing/2*[-1 1]);
%             title(sprintf('DiffScore = %d', diff_score));
            
%             subplot(3,3,[1 2 4 5 7 8]);
            hold on;
            plot(prev_coord(1), prev_coord(2), 'r*');
            hold off;
%             text(prev_coord(1)+5, prev_coord(2), num2str(diff_score),...
%                  'Color', 'r', 'FontWeight', 'bold', 'FontSize', 24);
        end
        
        % Get mouse input
        %------------------------------------------------------------
        [x, y, button] = ginput(1);
        switch button
            case 1 % Left click
                % Check if in bounds of the movie
                if (1 <= x) && (x <= width) && (1 <= y) && (y <= height)
                    coords(f,:) = [x y];
                    if (f == end_frame) % Final frame
                        cmd = input('  Press enter to continue... >> ', 's');
                        switch lower(cmd)
                            case 'b' % Redo final frame
                                f = end_frame;
                            otherwise
                                save(coord_savename, 'coords', 't', 'vid_source', 'reward_source');
                                break;
                        end % switch
                    else
                        f = f + 1; % Advance frame
                    end
                else
                    fprintf('  Please click within the video frame!\n');
                end
                
            case 3 % Right click. NOTE: There appears to be a bug where 
                   % repeated right clicks at the same point gets 
                   % interpreted as a left click. Watch out!
                if (f > start_frame)
                    f = f - 1; % Retract frame
                else
                    fprintf('  Already at first frame of Trial %d!\n', t);
                end
                
            otherwise
                fprintf('  Usage: Left click to mark feature; right click to go back a frame!\n');
        end
    end % while (f <= end_frame)
end

    function frame = get_frame(f)
        if preload_video
            frame = M(:,:,f);
        else
            frame = vid.read(f);
        end
    end % get_frame

end % function track_body_duopus

function is_nonzero = coord_is_nonzero(coord)
    is_nonzero = (coord(1)~=0) && (coord(2)~=0);
end % coord_is_nonzero