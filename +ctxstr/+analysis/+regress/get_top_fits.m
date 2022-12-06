function sorted_inds = get_top_fits(R2s)
% Given a list of R2s for each cell, return the cell indices corresponding
% to top R2 values in descending order.
%
% Format: sorted_inds(k,:) = [cell_ind R2_val]

[sorted_R2s, sorted_inds] = sort(R2s, 'descend');
sorted_inds = [sorted_inds sorted_R2s];