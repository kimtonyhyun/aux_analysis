function [M, info] = deinterlace_opto(movie_source, varargin)

csv_source = '';
laser_on = [];
lag = [];
for i = 1:length(varargin)
    vararg = varargin{i};
    if ischar(vararg)
        switch lower(vararg)
            case 'csv' % Saleae CSV export
                csv_source = varargin{i+1};
            case {'laser', 'laser_on'} % Explicitly provide laser-on frames
                laser_on = varargin{i+1};
            case 'lag' % Explicitly account for frame lags
                lag = varargin{i+1};
        end
    end
end

if isempty(laser_on)
    if ~isempty(csv_source)
        fprintf('Reading opto frames from CSV file (%s)...\n', csv_source);
        laser_on = parse_saleae_csv(csv_source);
    else
        error('No opto frame source provided!');
    end
end

% Load movie
%------------------------------------------------------------
fprintf('Loading movie...\n');
[~, ~, ext] = fileparts(movie_source);
switch lower(ext)
    case '.hdf5'
        M = load_movie(movie_source);
    case '.tif'
        M = load_scanimage_tif(movie_source);
end

num_frames = size(M,3);

info.laser_on = laser_on;
info.laser_off = setdiff(1:num_frames, laser_on);

% Deinterlacing parameters for N=11
%------------------------------------------------------------
deint_segments = [47 92;
                  139 184;
                  231 276;
                  323 368;
                  415 460];
buf = 0;
deint_segments(:,1) = deint_segments(:,1)-buf;
deint_segments(:,2) = deint_segments(:,2)+buf;
deint_lines = frame_segments_to_list(deint_segments);

% Splice opto frames together
%------------------------------------------------------------
opto_segments = frame_list_to_segments(laser_on);
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
        f1 = frames(m,1);
        f2 = frames(m,2);
        A1 = M(:,:,f1);
        A2 = M(:,:,f2);
        
        % Compute line lags
        lag1 = 0;
        lag2 = 0;
        if ~isempty(lag)
            lag1 = max([0 lag(f1)]);
            lag2 = max([0 lag(f2)]);
        end
        
        % Form composite image
        Ac = A1;
        Ac(deint_lines - lag1,:) = A2(deint_lines - lag2,:);
    
        % Stick back into original movie
        M(:,:,frames(m,1)) = Ac;
        M(:,:,frames(m,2)) = Ac;
    end
end

end % deinterlace_opto

function laser_on = parse_saleae_csv(sync_source)
    
    % Data format: [Time(s) FrameClk OptoEnabled]
    sync = csvread(sync_source, 1, 0); % Skip first line (header)
    num_rows = size(sync, 1);

    frame_clk_col = 2;
    opto_col = 3;

    % Detect opto frames
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

end % parse_saelae_csv
