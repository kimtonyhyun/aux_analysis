function sorted_inds = sort_R2s(R2s)
% Given a list of R2s for each cell, return the cell indices corresponding
% to top R2 values in descending order.
%
% Format: sorted_inds(k,:) = [R2_val cell_ind]

if size(R2s,2) == 1
    % Only R2 values provided. In this case, assume the values correspond
    % to cell IDs 1, 2, ..., length(R2s)
    R2s = [R2s (1:length(R2s))'];
end

sorted_inds = sortrows(R2s, 1, 'descend');