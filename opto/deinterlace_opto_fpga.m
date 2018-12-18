function M = deinterlace_opto_fpga(M)
% In the FPGA implementation of "frame interlace" the blocks are:
%   Block 1: Lines 1-103
%   Block 2: Lines 104-206
%   Block 3: Lines 207-309
%   Block 4: Lines 310-412
%   Block 5: Lines 413-512
% and the first frame starts with Blocks 2 and 4 blanked by the opto laser.
% Equivalently, odd frames image Blocks 1/3/5 and even frames image Blocks
% 2/4.

num_frames = size(M,3);
num_pairs = floor(num_frames/2);

for k = 1:num_pairs
    odd_frame_idx = 2*(k-1)+1;
    even_frame_idx = odd_frame_idx + 1;
    
    % Reconstruct the odd frame
    M(104:206,:,odd_frame_idx) = M(104:206,:,even_frame_idx);
    M(310:412,:,odd_frame_idx) = M(310:412,:,even_frame_idx);
    
    % Copy the odd onto even
    M(:,:,even_frame_idx) = M(:,:,odd_frame_idx);
end

% In case number of frames is odd, then copy over the result from the last
% deinterlaced pair. If even, then just repeating the odd-to-even copy on
% the last pair.
M(:,:,end) = M(:,:,end-1);
