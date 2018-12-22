function M = deopto_1in8(M)
% Frames 1, 9, 17, ... are blanked by the opto laser. Use the immediately
% following frame to fill

num_frames = size(M,3);

opto_frames = 1:8:num_frames;
source_frames = opto_frames + 1;

% If we end the trial on an opto frame, then this frame is replaced by the
% one preceding it.
if (opto_frames(end) == num_frames)
    source_frames(end) = num_frames - 1;
end

M(:,:,opto_frames) = M(:,:,source_frames);