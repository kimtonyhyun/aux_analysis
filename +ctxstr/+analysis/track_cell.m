function match_result = track_cell(day1, cell_ind1, days, map, matches)
% Matches are computed with respect to REC indices, whereas we assume that
% 'cell_ind1' and output cell indices are IND indices. So, we need to use
% 'map' to convert indices.

num_days = length(days);

% Format: [Day Cell-idx Cell-idx-Rec]
match_result = zeros(num_days, 3);
idx = 0;

cell_ind1_rec = map{days==day1}.ind2rec(cell_ind1);

for day2 = days
    if day2 == day1
        idx = idx + 1;
        match_result(idx,:) = [day1 cell_ind1 cell_ind1_rec];
    else
        m = matches{day1,day2}{cell_ind1_rec};
        if ~isempty(m) % Has a match
            cell_ind2_rec = m(1);
            cell_ind2 = map{days==day2}.rec2ind(cell_ind2_rec);

            idx = idx + 1;
            match_result(idx,:) = [day2 cell_ind2 cell_ind2_rec];
        end
    end
end
match_result = match_result(1:idx,:);