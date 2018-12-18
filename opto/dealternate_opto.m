function M = dealternate_opto(M)
% In the FPGA implementation of "frame alternate" _even_ frames are blanked
% by the opto laser

num_frames = size(M,3);

if mod(num_frames,2) % Odd
    M(:,:,2:2:end) = M(:,:,1:2:end-1);
else
    M(:,:,2:2:end) = M(:,:,1:2:end);
end