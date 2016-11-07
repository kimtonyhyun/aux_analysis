function track_body_duopus(vid_source, reward_source, varargin)
% Example usage: track_body_duopus('bottom0005.avi', 'rewards5.txt');

frame_halfwidth = 60; % Number of frames around the reward frame to analyze

vid = VideoReader(vid_source);
num_frames = vid.NumberOfFrames;
height = vid.Height;
width = vid.Width;

reward_frames = load(reward_source);
num_trials = length(reward_frames);

if isempty(varargin) % No intermediate save provided
    % Filename used in autosave
    timestamp = datestr(now, 'yymmdd-HHMMSS');
    coord_savename = sprintf('coords_%s.mat', timestamp);
    
    trials_to_analyze = 1:num_trials;
    coords = zeros(num_frames, 2); % Format: [x y]
else
    coord_savename = varargin{1};
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
hist_grid = 0:5:50;
hist_spacing = hist_grid(2) - hist_grid(1);

for t = trials_to_analyze
    fprintf('%s: Trial %d of %d...\n', datestr(now), t, num_trials);
    
    % Trial frames to track
    reward_frame = reward_frames(t);
    start_frame = max(1, reward_frame-frame_halfwidth);
    end_frame = min(num_frames, reward_frame+frame_halfwidth);
    
    f = start_frame;
    while (f <= end_frame)
        % Display frame
        %------------------------------------------------------------
        subplot(3,3,[1 2 4 5 7 8]);
        current_frame = vid.read(f);
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
            left = max(1, prev_coord(1)-roi_halfwidth);
            right = min(width, prev_coord(1)+roi_halfwidth);
            top = max(1, prev_coord(2)-roi_halfwidth);
            bottom = min(height, prev_coord(2)+roi_halfwidth);
            
            prev_frame = vid.read(f-1);
            prev_sample = single(prev_frame(top:bottom, left:right, 1));
            subplot(3,3,3);
            imagesc(prev_sample, [0 255]);
            colormap gray;
            axis image;
            hold on;
            plot(roi_halfwidth+1, roi_halfwidth+1, 'r*');
            hold off;
            set(gca, 'XTickLabel', '', 'YTickLabel', '');
            title(sprintf('Previous frame (%d)', f-1));
            
            current_sample = single(current_frame(top:bottom, left:right, 1));
            subplot(3,3,6);
            imagesc(current_sample, [0 255]);
            axis image;
            set(gca, 'XTickLabel', '', 'YTickLabel', '');
            title(sprintf('Current frame (%d)', f));
            
            diff_sample = abs(current_sample - prev_sample);
            diff_sample = diff_sample(:);
            diff_score = round(prctile(diff_sample, 90));
            subplot(3,3,9);
            hist(diff_sample, hist_grid);
            set(get(gca, 'child'), 'FaceColor', 0.2*[1 1 1]);
            xlim([hist_grid(1) hist_grid(end)]+hist_spacing/2*[-1 1]);
            title(sprintf('DiffScore = %d', diff_score));
            
            subplot(3,3,[1 2 4 5 7 8]);
            hold on;
            plot(prev_coord(1), prev_coord(2), 'r*');
            hold off;
            text(prev_coord(1)+5, prev_coord(2), num2str(diff_score),...
                 'Color', 'r', 'FontWeight', 'bold', 'FontSize', 24);
        end
        
        % Get mouse input
        %------------------------------------------------------------
        [x, y, button] = ginput(1);
        switch button
            case 1 % Left click
                % Check if in bounds of the movie
                if (1 <= x) && (x <= width) && (1 <= y) && (y <= height)
                    coords(f,:) = [x y];
                    f = f + 1; % Advance frame
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
    
    % Save ongoing result and prompt user
    save(coord_savename, 'coords', 't', 'vid_source', 'reward_source');
    input('  Press enter to continue... >> ');
end

end % function track_body_duopus

function is_nonzero = coord_is_nonzero(coord)
    is_nonzero = (coord(1)~=0) && (coord(2)~=0);
end % coord_is_nonzero