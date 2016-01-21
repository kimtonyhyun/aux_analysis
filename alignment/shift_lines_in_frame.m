function shifted_frame = shift_lines_in_frame(frame, shift_px)
% Linearly shifts the odd-even lines in a 2p image.
%
% Inputs:
%   frame: 2p image data [slow_axis x fast_axis]
%   shift_px: number of pixels to shift (can be fractional)
%
% Outputs:
%   shifted_frame: Shifted 2p image data [slow_axis x fast_axis]
%
% Note: Pixel values of -1 indicate the correction required sampling beyond
%       the acquired image.
%

% Data needs to be floating point for interpolation
frame = double(frame);

[num_lines, num_pixels] = size(frame);
fast_axis = 1:num_pixels;

% Apply shift to image
%------------------------------------------------------------
extrap_val = -1;

shifted_frame = zeros(size(frame));
for k = 1:num_lines
    line = frame(k,:);
    if mod(k,2) % Odd line
        corrected_axis = fast_axis + shift_px;
    else % Even line
        corrected_axis = fast_axis - shift_px;
    end
    shifted_frame(k,:) = interp1(fast_axis, line, corrected_axis, 'pchip', extrap_val);
end