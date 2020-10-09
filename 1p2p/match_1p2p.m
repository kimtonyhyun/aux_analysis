function matched_corrlist = match_1p2p(ds1, ds2, tform)
% For each 2P cell in ds2, attempt to find a matching 1P cell in ds1.

app_name = '1P/2P matching';

% First, pre-compute all correlations. Results are sorted by correlation
% value (descending).
corrlist = compute_corrlist(ds1, ds2);

% Sort corrlist by ds_source cell index
corrlist = sortrows(corrlist, 2, 'ascend');

num_cells1 = ds1.num_classified_cells;
num_cells2 = ds2.num_classified_cells;

% Preallocate output
matched_corrlist = zeros(num_cells2, 3);

hf = figure;

i = 1; % Loops over ds1 cells
j = 1; % Loops over ds2 cells
while (1)
    % Block of corrlist for the j-th cell in ds2
    rows = (1+(j-1)*num_cells1):(j*num_cells1);
    corrlist_j = corrlist(rows, :);
    
    corrdata = corrlist_j(i,:);
    show_corr(ds1, corrdata(1), ds2, corrdata(2), corrdata(3),...
        'names', {'1P', '2P'},...
        'zsc',...
        'overlay', tform);
    
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
            % Set ds1 cell index
            if (1 <= val) && (val <= num_cells1)
                i = val;
            end
        else
            switch resp(1)
                case {'c', 'm', 'y'} % Indicate match
                    matched_corrlist(j,:) = corrdata;
                    fprintf('  1P cell=%d assigned to 2P cell=%d!\n',...
                        corrdata(1), corrdata(2));

                    % Increment 2P cell index
                    j = j + 1;
                    j = min(num_cells2, j);
                    i = 1;

                case 'n' % No match for this 2P cell
                    matched_corrlist(j,:) = [0 0 0];
                    fprintf('  2P cell=%d has no match!\n',...
                        corrdata(2));
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