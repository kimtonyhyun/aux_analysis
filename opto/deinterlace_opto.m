function [M, info] = deinterlace_opto(movie_source, sync_source)
% TODO:
%   - Line-level correction of the slave movie

% Data format: [Time(s) FrameClk OptoEnabled]
%------------------------------------------------------------
sync = csvread(sync_source, 1, 0); % Skip first line (header)
num_rows = size(sync, 1);

frame_clk_col = 2;
opto_col = 3;

% Detect opto frames
%------------------------------------------------------------
opto_frame = zeros(num_rows, 1); % Preallocate

frame_idx = 0;
frame = sync(1,frame_clk_col);
for k = 2:num_rows
    prev_frame = frame;
    frame = sync(k,frame_clk_col);
    if (~prev_frame && frame) % Positive edge
        frame_idx = frame_idx + 1;
        if sync(k,opto_col)
            opto_frame(frame_idx) = 1;
        end
    end
end
opto_frame = opto_frame(1:frame_idx,:);
laser_on = find(opto_frame)';
opto_segments = frame_list_to_segments(laser_on);

info.laser_on = laser_on;
info.laser_off = setdiff(1:frame_idx, laser_on);

% Load movie
%------------------------------------------------------------
fprintf('Loading movie...\n');
M = load_movie(movie_source);

% Splice opto frames together
%------------------------------------------------------------
num_segments = size(opto_segments,1);

for k = 1:num_segments
    fprintf('Deinterlacing opto segment %d of %d...\n',k, num_segments);
    frames = opto_segments(k,1):opto_segments(k,2);
    num_frames = length(frames);
    if (mod(num_frames, 2) == 1) % is odd
        frames = [frames frames(end-1)]; %#ok<AGROW>
        num_frames = num_frames + 1;
    end
    frames = reshape(frames, 2, num_frames/2)';
    
    num_composite_frames = size(frames,1);
    for m = 1:num_composite_frames
        A1 = M(:,:,frames(m,1));
        A2 = M(:,:,frames(m,2));
        
        % Form composite image
%         deint_lines = [103:204 307:408]; % N=5 subfields
        deint_lines = [47:92 139:184 231:276 323:368 415:460]; % N=11
        Ac = A1;
        Ac(deint_lines,:) = A2(deint_lines,:);
    
        % Stick back into original movie
        M(:,:,frames(m,1)) = Ac;
        M(:,:,frames(m,2)) = Ac;
    end
end

end % deinterlace_opto
