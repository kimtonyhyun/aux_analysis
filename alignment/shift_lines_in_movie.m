function M_shift = shift_lines_in_movie(M, shift_px)

M_shift = zeros(size(M));
num_frames = size(M, 3);

for k = 1:num_frames
    if (mod(k, 500) == 0)
        fprintf('%s: Aligning frame %d of %d...\n',...
            datestr(now), k, num_frames);
    end
    frame = shift_lines_in_frame(M(:,:,k), shift_px);
    
    % (Optional) Fill in missing values
    frame = fill_missing_pixels(frame);
    
    M_shift(:,:,k) = frame;
end