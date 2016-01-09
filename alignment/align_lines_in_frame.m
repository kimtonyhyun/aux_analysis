function [aligned_frame, info] = align_lines_in_frame(frame, pos_data, varargin)
% Performs correction of odd-even line offset, given a simultaneously
% acquired galvo position signal.
%
% Inputs:
%   frame: 2p image data [slow_axis x fast_axis]
%   pos_data: Samples of the fast-axis galvo position
%
% Outputs:
%   aligned_frame: Corrected 2p image data [slow_axis x fast_axis]
%   info: Auxiliary information regarding the correction
%
% Note: Pixel values of -1 indicate that the correction required sampling
%       beyond the acquired image.
%
% TODO:
%   Issue warning when the position data signal is clipped at DAQ bounds
%

pos_ref_odd = [];
pos_ref_even = [];
for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case {'pos_ref', 'ref'}
                info_in = varargin{k+1};
                pos_ref_odd = info_in.pos_ref.odd;
                pos_ref_even = info_in.pos_ref.even;
        end
    end
end

% Data needs to be floating point for interpolation
frame = double(frame);
pos_data = double(pos_data);

[num_lines, num_pixels] = size(frame);
fast_axis = 1:num_pixels;

% Compute the mean galvo position profiles of odd and even lines
%------------------------------------------------------------
pos_data = pos_data(1:(end-1),:); % Omit the last line, which can glitch
pos_data_odd = pos_data(1:2:end,:);
pos_data_even = pos_data(2:2:end,:);

pos_odd = mean(pos_data_odd);
pos_even = mean(pos_data_even);

% Linear (polyfit) to the steady state, i.e. at the center of swing
%------------------------------------------------------------
center = (num_pixels-1)/2 + 1;
half_width = floor(num_pixels / 20);
ss_inds = floor(center-half_width):ceil(center+half_width);

fast_axis_ss = fast_axis(ss_inds);
odd_lin_coeffs = polyfit(fast_axis_ss, pos_odd(ss_inds), 1);
even_lin_coeffs = polyfit(fast_axis_ss, pos_even(ss_inds), 1);

% Deviation between the linear and full trajectories is the correction
% factor to be applied
%------------------------------------------------------------

% If the reference linear trajectory was not externally provided (see
% varargin handling), then use linear fit of pos_data from this frame.
if isempty(pos_ref_odd)
    pos_ref_odd = polyval(odd_lin_coeffs, fast_axis);
end
if isempty(pos_ref_even)
    pos_ref_even = polyval(even_lin_coeffs, fast_axis);
end

% Conversion factor from galvo position signal to pixels
range_odd = pos_ref_odd(end) - pos_ref_odd(1);
range_even = pos_ref_even(end) - pos_ref_even(1);
pos2pix = (num_pixels - 1) / mean([range_odd range_even]);

pixel_offset_odd = pos2pix * (pos_ref_odd - pos_odd);
pixel_offset_even = pos2pix * (pos_ref_even - pos_even);

% Apply correction to image
%------------------------------------------------------------
extrap_val = -1;

corrected_odd_axis = fast_axis + pixel_offset_odd;
corrected_even_axis = fast_axis + pixel_offset_even;

aligned_frame = zeros(size(frame));
for k = 1:num_lines
    line = frame(k,:);
    if mod(k,2) % Odd line
        aligned_line = interp1(fast_axis, line, corrected_odd_axis, [], extrap_val);
    else % Even line
        aligned_line = interp1(fast_axis, line, corrected_even_axis, [], extrap_val);
    end
    aligned_frame(k,:) = aligned_line;
end

% Pack auxiliary info for output
%------------------------------------------------------------
info.pos_ref.odd = pos_ref_odd;
info.pos_ref.even = pos_ref_even;

info.pixel_offset.odd = pixel_offset_odd;
info.pixel_offset.even = pixel_offset_even;

info.extrap_val = extrap_val;

end % align_lines