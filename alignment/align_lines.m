function [aligned_frame, info] = align_lines(frame, pos_data, varargin)
% Performs correction of odd-even line offset, given a simultaneously
% acquired galvo position signal.
%
% Inputs:
%   frame: 2p image data [slow_axis x fast_axis]
%   pos_data: Samples of the fast-axis galvo position
%
% Note: Pixel values of -1 indicate that the correction required sampling
%       beyond the acquired image.
%

pos_odd_ref = [];
pos_even_ref = [];
for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case {'pos_ref', 'ref'}
                info_in = varargin{k+1};
                pos_odd_ref = info_in.pos_odd_ref;
                pos_even_ref = info_in.pos_even_ref;
        end
    end
end

% Needs to be floating point for interpolation
frame = double(frame);
pos_data = double(pos_data);

[num_lines, num_pixels] = size(frame);
fast_axis = 1:num_pixels;

% Compute the mean galvo position profiles of odd and even lines
%------------------------------------------------------------
pos_data = pos_data(1:(end-1),:); % Omit the last line, which glitches
pos_data_odd = pos_data(1:2:end,:);
pos_data_even = pos_data(2:2:end,:);

pos_odd = mean(pos_data_odd);
pos_even = mean(pos_data_even);

% Linear (polyfit) to the steady state, at the center of swing
%------------------------------------------------------------
center = (num_pixels-1)/2 + 1;
half_width = floor(num_pixels / 20);
ss_inds = floor(center-half_width):ceil(center+half_width);

fast_axis_ss = fast_axis(ss_inds);
odd_lin_coeffs = polyfit(fast_axis_ss, pos_odd(ss_inds), 1);
even_lin_coeffs = polyfit(fast_axis_ss, pos_even(ss_inds), 1);

pos_odd_lin = polyval(odd_lin_coeffs, fast_axis);
pos_even_lin = polyval(even_lin_coeffs, fast_axis);

% Deviation between the linear and full trajectories is the correction
% factor to be applied
%------------------------------------------------------------
pos_odd_range = pos_odd_lin(end) - pos_odd_lin(1);
pos_even_range = pos_even_lin(end) - pos_even_lin(1);

% Conversion factor from galvo position signal to pixels
pos2pix = (num_pixels - 1) /...
          mean([pos_odd_range pos_even_range]);

if isempty(pos_odd_ref)
    pos_odd_ref = pos_odd_lin;
end
if isempty(pos_even_ref)
    pos_even_ref = pos_even_lin;
end

pixel_offset_odd = pos2pix * (pos_odd_ref - pos_odd);
pixel_offset_even = pos2pix * (pos_even_ref - pos_even);

% Apply correction to image
%------------------------------------------------------------
extrap_val = -1;

odd_grid = fast_axis + pixel_offset_odd;
even_grid = fast_axis + pixel_offset_even;

aligned_frame = zeros(size(frame));
for k = 1:num_lines
    line = frame(k,:);
    if mod(k,2) % Odd line
        aligned_line = interp1(fast_axis, line, odd_grid, [], extrap_val);
    else % Even line
        aligned_line = interp1(fast_axis, line, even_grid, [], extrap_val);
    end
    aligned_frame(k,:) = aligned_line;
end

% Pack auxiliary info
info.pos_odd_ref = pos_odd_ref;
info.pos_even_ref = pos_even_ref;

end % align_lines