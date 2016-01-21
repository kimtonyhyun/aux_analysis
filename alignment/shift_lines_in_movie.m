function M_shift = shift_lines_in_movie(M, shift_px)

M_shift = zeros(size(M));
num_frames = size(M, 3);

for k = 1:num_frames
    if (mod(k, 500) == 0)
        fprintf('%s: Aligning frame %d of %d...\n',...
            datestr(now), k, num_frames);
    end
    M_shift(:,:,k) = shift_lines_in_frame(M(:,:,k), shift_px);
end