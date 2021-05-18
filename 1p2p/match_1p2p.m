function [matched_corrlist, non_matched_corrlist] = match_1p2p(ds1, ds2, tform, fps)
% For each 2P cell in ds2, attempt to find a matching 1P cell in ds1.
% Inputs:
%   - ds1: DaySummary of 1P data
%   - ds2: DaySummary of 2P data
%   - tform: Spatial transform to match 2P cellmap onto the 1P cellmap
%            (output of 'run_alignment')
%   - fps: Frame rate, used for defining active periods in traces.
%
% Output format:
%   corrlist: [1P-idx 2P-idx corr-val FGF FEV], where
%       - FGF: Fraction of frames with good fit
%       - FEV: Fraction explained variance
%

app_name = 'Match 1P/2P';

num_cells1 = ds1.num_classified_cells;
num_cells2 = ds2.num_classified_cells;

% Preallocate output
% Format: 
matched_corrlist = zeros(num_cells2, 5);
non_matched_corrlist = zeros(num_cells2, 5); % For development purposes

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
    
    clf;
    metric = show_1p2p(ds1, ds1_cell_idx, ds2, ds2_cell_idx, tform, fps);

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
                case 'c' % Indicates match
                    matched_corrlist(j,:) = [corrlist_j(i,:) metric.fraction_good_fit metric.fraction_variance_explained];
                    non_matched_corrlist(j,:) = [0 0 0 0 0];
                    fprintf('  2P cell=%d matched to 1P cell=%d!\n', ds2_cell_idx, ds1_cell_idx);

                    % Increment 2P cell index
                    j = j + 1;
                    if j > num_cells2
                        cprintf('blue', 'Matched all cells!\n');
                        j = num_cells2;
                    else
                        i = 1;
                    end

                case 'n' % No match for this 2P cell
                    matched_corrlist(j,:) = [0 0 0 0 0];
                    non_matched_corrlist(j,:) = [corrlist_j(i,:) metric.fraction_good_fit metric.fraction_variance_explained];
                    fprintf('  2P cell=%d has no match!\n', ds2_cell_idx);
                    
                    j = j + 1;
                    if j > num_cells2
                        cprintf('blue', 'Matched all cells!\n');
                        j = num_cells2;
                    else
                        i = 1;
                    end
                    
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
keep_rows = matched_corrlist(:,1) > 0;
matched_corrlist = matched_corrlist(keep_rows,:);

keep_rows = non_matched_corrlist(:,1) > 0;
non_matched_corrlist = non_matched_corrlist(keep_rows,:);
