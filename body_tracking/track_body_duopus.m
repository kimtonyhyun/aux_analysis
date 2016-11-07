function track_body_duopus(vid_source, reward_source, varargin)
% Example usage: track_body_duopus('bottom0005.avi', 'rewards5.txt');

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
    
    trials_complete = saved.t; % We save only completed trials
    fprintf('Resuming from Trial %d per "%s"...\n', trials_complete+1, coord_savename);
    
    trials_to_analyze = (trials_complete+1):num_trials;
    coords = saved.coords;
end

frame_halfwidth = 60;
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
        imagesc(vid.read(f)); truesize;
        title(sprintf('Frame %d (Trial %d: Frames %d to %d)',...
                      f, t, start_frame, end_frame));
        
        % Display existing coordinate, if it exists
        old_coord = coords(f,:);
        if (old_coord(1)~=0) && (old_coord(2)~=0)
            hold on;
            plot(old_coord(1), old_coord(2), '*');
            hold off;
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