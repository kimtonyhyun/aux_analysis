function aligned_frame = align_lines(frame, pos_data)
% Performs correction of odd-even line offset, given a simultaneously
% acquired galvo position signal.
%
% Inputs:
%   frame: 2p image data [slow_axis x fast_axis]
%   pos_data: Samples of the fast-axis galvo position
%

% Knobs
polyfit_order = 4;
debug = 1;

% Needs to be floating point for interpolation
frame = double(frame);
pos_data = double(pos_data);

[num_lines, num_pixels] = size(frame);
fast_axis = 1:num_pixels;

% Compute the mean galvo position profiles of odd and even lines, then
% perform polynomial fits.
%------------------------------------------------------------
pos_data = pos_data(1:(end-1),:); % Omit the last line, which glitches
pos_data_odd = pos_data(1:2:end,:);
pos_data_even = pos_data(2:2:end,:);

pos_odd = mean(pos_data_odd);
pos_even = mean(pos_data_even);

% Polyfit to entire data
p_odd = polyfit(fast_axis, pos_odd, polyfit_order);
p_even = polyfit(fast_axis, pos_even, polyfit_order);

% Linear (polyfit) to the steady state, assumed to be center of swing
center = (num_pixels-1)/2 + 1;
half_width = floor(num_pixels / 20);
ss_inds = floor(center-half_width):ceil(center+half_width);

fast_axis_ss = fast_axis(ss_inds);
p_odd_lin = polyfit(fast_axis_ss, pos_odd(ss_inds), 1);
p_even_lin = polyfit(fast_axis_ss, pos_even(ss_inds), 1);

% Evaluate polyfits
%------------------------------------------------------------
x = linspace(1, num_pixels, 1000);

odd_fit.full = polyval(p_odd, x);
odd_fit.lin  = polyval(p_odd_lin, x);
odd_fit.lin_range = odd_fit.lin(end) - odd_fit.lin(1);

even_fit.full = polyval(p_even, x);
even_fit.lin  = polyval(p_even_lin, x);
even_fit.lin_range = even_fit.lin(end) - even_fit.lin(1);

% Conversion factor from galvo position signal to pixels
pos2pix = (num_pixels - 1) /...
          mean([odd_fit.lin_range even_fit.lin_range]);

% Deviation between the linear and full trajectories is the correction
% factor to be applied
%------------------------------------------------------------
pixel_offset_odd = pos2pix * (odd_fit.lin - odd_fit.full);
pixel_offset_even = pos2pix * (even_fit.lin - even_fit.full);

if debug
    subplot(121);
    
    % Raw data
    plot(pos_odd, 'b.'); hold on;
    plot(pos_even, 'r.');
    grid on;
    xlim([1 num_pixels]);
    xlabel('Fast axis [pixels]');
    ylabel('Galvo position [a.u.]');
    legend('Odd lines', 'Even lines', 'Location', 'NorthWest');
    
    % Indicate steady state pixels with circles
    plot(fast_axis_ss, pos_odd(ss_inds), 'o');
    plot(fast_axis_ss, pos_even(ss_inds), 'ro');
    
    % Polyfit to full data
    plot(x, odd_fit.full);
    plot(x, odd_fit.lin, '--');
    plot(x, even_fit.full, 'r');
    plot(x, even_fit.lin, 'r--');
    title(sprintf('Full polyfit order: %d', polyfit_order));
    
    subplot(122);
    plot(x, pixel_offset_odd); hold on;
    plot(x, pixel_offset_even, 'r');
    grid on;
    xlim([1 num_pixels]);
    xlabel('Fast axis [pixels]');
    ylabel('Pixel offset [pixels]');
end

% Apply correction to image
%------------------------------------------------------------
extrap_val = -1;

odd_grid = fast_axis + interp1(x, pixel_offset_odd, fast_axis);
even_grid = fast_axis + interp1(x, pixel_offset_even, fast_axis);

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

end % align_lines