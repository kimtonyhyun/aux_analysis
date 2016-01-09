function frame = fill_missing_pixels(frame)
% Look for missing pixel values (marked with negative values) in the frame
% and replace with pixel values taken from adjacent lines.

num_lines = size(frame, 1);

% First (top) line
line = frame(1,:);
pixels_to_replace = find(line < 0);
frame(1, pixels_to_replace) = frame(2, pixels_to_replace);

% Intermediate lines
for k = 2:(num_lines-1)
    line = frame(k,:);
    pixels_to_replace = find(line < 0);
    frame(k, pixels_to_replace) = mean(...
        [frame(k-1, pixels_to_replace); frame(k+1, pixels_to_replace)]);
end

% Last (bottom) line
line = frame(num_lines,:);
pixels_to_replace = find(line < 0);
frame(num_lines, pixels_to_replace) = frame(num_lines-1, pixels_to_replace);
