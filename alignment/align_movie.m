function M_aligned = align_movie(M_image, M_pos)

M_aligned = zeros(size(M_image));
num_frames = size(M_aligned, 3);

% Special handling for the first frame
[frame, align_info] = align_lines(M_image(:,:,1), M_pos(:,:,1));
M_aligned(:,:,1) = frame;

for k = 2:num_frames
    if (mod(k, 100) == 0)
        fprintf('%s: Aligning frame %d of %d...\n',...
            datestr(now), k, num_frames);
    end
    frame = M_image(:,:,k);
    pos_data = M_pos(:,:,k);
    
    % Correct for galvo nonlinearity
    frame =  align_lines(frame, pos_data, 'ref', align_info);
    
    % Store results
    M_aligned(:,:,k) = frame;
end