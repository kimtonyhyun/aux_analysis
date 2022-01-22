function save_tdt_class(ds, tdt_class_file)

% Load the tdTomato classification from the provided text file
fid = fopen(tdt_class_file, 'r');
tdt_class = textscan(fid, '%d %s', 'Delimiter', ',');
fclose(fid);
tdt_class = tdt_class{2};

% Cells are added to the tdTomato 'pos' and 'neg' lists, _only_ if they are
% classified to be cells in the DaySummary
num_cells = ds.num_cells;

pos = zeros(1,num_cells); num_pos = 0;
neg = zeros(1,num_cells); num_neg = 0;
for k = 1:num_cells
    if ds.is_cell(k)
        if strcmp(tdt_class{k}, 'cell') % tdTomato-positive
            num_pos = num_pos + 1;
            pos(num_pos) = k;
        else
            num_neg = num_neg + 1;
            neg(num_neg) = k;
        end
    end
end
pos = pos(1:num_pos);
neg = neg(1:num_neg);
fprintf('Found %d tdTomato-positive and %d tdTomato-negative cells (%d total)\n',...
    num_pos, num_neg, num_pos + num_neg);

% Save results to MAT file
outfile = sprintf('tdt_%s.mat', datestr(now, 'yymmdd-HHMMSS'));
save(outfile, 'pos', 'neg');