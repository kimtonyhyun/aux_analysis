function M_aligned = align_movie(M_image, M_pos)

M_aligned = zeros(size(M_image));
num_frames = size(M_aligned, 3);

for k = 1:num_frames
    if (mod(k, 100) == 0)
        fprintf('%s: Aligning frame %d of %d...\n',...
            datestr(now), k, num_frames);
    end
    frame = M_image(:,:,k);
    pos_data = M_pos(:,:,k);
    M_aligned(:,:,k) = align_lines(frame, pos_data);
end