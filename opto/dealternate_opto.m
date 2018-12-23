function M = dealternate_opto(M)
% In the FPGA implementation of "frame alternate" _odd_ frames are blanked
% by the opto laser

num_frames = size(M,3);

% LEGACY: 'optocontroller_20181217.bit' blanks the EVEN frames
if mod(num_frames,2) % Odd
    M(:,:,2:2:end) = M(:,:,1:2:end-1);
else
    M(:,:,2:2:end) = M(:,:,1:2:end);
end

% 'optocontroller_20181221.bit' blanks the ODD frames
% if mod(num_frames,2) % Total number of frames is odd
%     M(:,:,1:2:end-1) = M(:,:,2:2:end);
%     M(:,:,end) = M(:,:,end-1);
% else
%     M(:,:,1:2:end) = M(:,:,2:2:end);
% end
