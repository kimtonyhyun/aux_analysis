function M_aligned = align_movie(M_image, M_pos)

M_aligned = zeros(size(M_image));
num_frames = size(M_aligned, 3);

% Special handling for the first frame, which we assume is ideally aligned
[frame, align_info] = align_lines(M_image(:,:,1), M_pos(:,:,1));
M_aligned(:,:,1) = frame;

for k = 2:num_frames
    if (mod(k, 100) == 0)
        fprintf('%s: Aligning frame %d of %d...\n',...
            datestr(now), k, num_frames);
    end
    frame = M_image(:,:,k);
    pos_data = M_pos(:,:,k);
    
    % Correct for galvo drift
    frame = align_lines(frame, pos_data, 'ref', align_info);
    
    % (Optional) Fill in missing values
    frame = fill_frame(frame);
    
    % Store results
    M_aligned(:,:,k) = frame;
end

end % align_movie

function frame = fill_frame(frame)
% Look for missing (negative) pixel values in the frame, and replace with
% pixel values taken from adjacent lines

num_lines = size(frame, 1);

% First line
line = frame(1,:);
pixels_to_replace = find(line < 0);
frame(1, pixels_to_replace) = frame(2, pixels_to_replace);

for k = 2:(num_lines-1)
    line = frame(k,:);
    pixels_to_replace = find(line < 0);
    frame(k, pixels_to_replace) = mean(...
        [frame(k-1, pixels_to_replace); frame(k+1, pixels_to_replace)]);
end

% Last line
line = frame(num_lines,:);
pixels_to_replace = find(line < 0);
frame(num_lines, pixels_to_replace) = frame(num_lines-1, pixels_to_replace);

end