function matched_corrlist = match_1p2p(ds1, ds2, tform)
% For each 2P cell in ds2, attempt to find a matching 1P cell in ds1.

app_name = '1P/2P matching';

num_cells1 = ds1.num_classified_cells;
num_cells2 = ds2.num_classified_cells;

matched_corrlist = zeros(num_cells2, 3); % Preallocate output

% First, pre-compute all correlations between classified cells.
corrlist = compute_corrlist(ds1, ds2); % [1P-idx 2P-idx corr-val]
corrlist = sortrows(corrlist, 2, 'ascend'); % Sort by 2P cell index

% Next, precompute distances between cells using their center-of-mass. Note
% that this computation is performed for all sources, not just those
% classified to be a cell.
num_all_cells1 = ds1.num_cells;
num_all_cells2 = ds2.num_cells;

coms1 = cell2mat({ds1.cells.com}); % coms1(:,k) is the COM of the k-th cell
coms2 = cell2mat({ds2.cells.com});
coms2 = transformPointsForward(tform, coms2')';

D = zeros(num_all_cells1, num_all_cells2);
for i = 1:num_all_cells1
    for j = 1:num_all_cells2
        D(i,j) = norm(coms1(:,i)-coms2(:,j));
    end
end

hf = figure;

j = 1; % Loops over ds2 cells
i = 1; % Loops over ds1 cells
while (1)
    % Block of corrlist for the j-th cell in ds2
    rows = (1+(j-1)*num_cells1):(j*num_cells1);
    corrlist_j = corrlist(rows, :);
    
    ds1_cell_idx = corrlist_j(i,1);
    ds2_cell_idx = corrlist_j(i,2);
    corr_val = corrlist_j(i,3);
    
    show_corr(ds1, ds1_cell_idx, ds2, ds2_cell_idx, corr_val,...
        'names', {'1P', '2P'},...
        'zsc',...
        'overlay', tform,...
        'zoom_target', 2);

    prompt = sprintf('%s (2P idx j=%d of %d; 1P idx i=%d of %d) >> ',...
                      app_name,...
                      j, num_cells2,...
                      i, num_cells1);
    resp = strtrim(input(prompt, 's'));

    resp = lower(resp);
    if isempty(resp)
        % Increment ds1 cell index
        i = i + 1;
        i = min(num_cells1, i);
    else
        val = str2double(resp);
        if (~isnan(val)) % Is a number
            if (val == 0)
                % Find the nearest cell
                [~, ds1_cell_idx] = min(D(:,ds2_cell_idx));
                i = find(corrlist_j(:,1)==ds1_cell_idx, 1);
            elseif (1 <= val) && (val <= num_cells1)
                % Set ds1 cell index
                i = val;
            end
        else
            switch resp(1)
                case {'c', 'm', 'y'} % Indicate match
                    matched_corrlist(j,:) = corrlist_j(i,:);
                    fprintf('  2P cell=%d matched to 1P cell=%d!\n',...
                        ds2_cell_idx, ds1_cell_idx);

                    % Increment 2P cell index
                    j = j + 1;
                    j = min(num_cells2, j);
                    i = 1;

                case 'n' % No match for this 2P cell
                    matched_corrlist(j,:) = [0 0 0];
                    fprintf('  2P cell=%d has no match!\n',...
                        ds2_cell_idx);
                    j = j + 1;
                    j = min(num_cells2, j);
                    i = 1;
                    
                case 'p' % Previous
                    j = j - 1;
                    j = max(1, j);
                    i = 1;

                case 'q' % Exit
                    close(hf);
                    break;

                otherwise
                    fprintf('  Could not parse "%s"\n', resp);
            end
        end
    end
end % while (1)

% Remove empty rows in 'matched_corrlist'
keep_rows = matched_corrlist(:,2) > 0;
matched_corrlist = matched_corrlist(keep_rows,:);