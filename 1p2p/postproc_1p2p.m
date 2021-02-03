%%
%------------------------------------------------------------
% PART 1: Initial assessment and filter transfer across 1P-2P
%------------------------------------------------------------

clear all;

path_to_dataset1 = '1P';
path_to_dataset2 = '2P';

ds = DaySummary([], fullfile(path_to_dataset1, 'ext1/proj_ti4'));
ds2 = DaySummary([], fullfile(path_to_dataset2, 'ext1/proj_ti4'));

%% Temporal correlations facilitate identification of matched cells

corrlist_1p2p = compute_corrlist(ds, ds2);
browse_corrlist(corrlist_1p2p, ds, ds2, 'names', {path_to_dataset1, path_to_dataset2}, 'zsc');

%% Perform spatial alignment

close all;

% Note that while we don't use 'm_XtoY' as part of the matching process, we
% _do_ need to compute it, as the output of the matching procedure
% determines which filters are transferred across modalities.
[m_1to2, m_2to1, info] = run_alignment(ds, ds2); %#ok<*ASGLU>
save('match_pre', 'm_1to2', 'm_2to1', 'info', '-v7.3');

%% Save image of the spatial alignment

dataset_name = dirname;
num_cells_1p = ds.num_classified_cells;
num_cells_2p = ds2.num_classified_cells;

title_str = sprintf('%s (PRE-merge)\n%s (%d cells; blue) vs. %s (%d cells; red)',...
    dataset_name, path_to_dataset1, num_cells_1p, path_to_dataset2, num_cells_2p);
title(title_str);
set(gca, 'FontSize', 18);
print('-dpng', 'overlay_pre');

%% Transfer cell filters across modalities
% Just needs 'path_to_datasetX' and 'info' from run_alignment

close all;

merge_dirname = 'merge';

cprintf('blue', 'Transferring filters from 2P to 1P...\n');
filename_1p = get_most_recent_file(path_to_dataset1, '*_dff_ti4.hdf5');
recname_2to1 = backapply_filters(info.filters_2to1.im, filename_1p, 'fix', 'percentile');
path_to_merge = fullfile(path_to_dataset1, merge_dirname, 'from_2p');
mkdir(path_to_merge);
movefile(recname_2to1, path_to_merge);

cprintf('blue', 'Transferring filters from 1P to 2P...\n');
filename_2p = get_most_recent_file(path_to_dataset2, '*_zsc_ti4.hdf5');
recname_1to2 = backapply_filters(info.filters_1to2.im, filename_2p, 'fix', 'percentile');
path_to_merge = fullfile(path_to_dataset2, merge_dirname, 'from_1p');
mkdir(path_to_merge);
movefile(recname_1to2, path_to_merge);

cprintf('blue', 'Done with transfers!\n');

%%
%------------------------------------------------------------
% PART 2: Classify 1P-2P merged filters
%------------------------------------------------------------

clearvars -except merge_dirname;
close all;

switch dirname
    case '1P'
        rec1_path = 'ext1/proj_ti4';
        rec2_path = fullfile(merge_dirname, 'from_2p');
        movie_filename = get_most_recent_file('', '*_dff_ti4.hdf5');
        
    case '2P'
        rec1_path = 'ext1/proj_ti4';
        rec2_path = fullfile(merge_dirname, 'from_1p');
        movie_filename = get_most_recent_file('', '*_zsc_ti4.hdf5');
        
    otherwise
        fprintf('Please run script in "1P" or "2P" subdirectory!\n');
        return;
end
rec_out_path = fullfile(merge_dirname, 'concat');

rec1 = load(get_most_recent_file(rec1_path, 'rec_*.mat'));
rec2 = load(get_most_recent_file(rec2_path, 'rec_*.mat'));

filters = cat(3, rec1.filters, rec2.filters);
traces = cat(2, rec1.traces, rec2.traces);

info.type = 'merge';
info.num_pairs = rec1.info.num_pairs + rec2.info.num_pairs;
info.merge = {rec1_path, rec2_path};

merged_rec = save_rec(info, filters, traces);
cprintf('blue', 'Merged "%s" (%d cells) and "%s" (%d cells)\n',...
    rec1_path, rec1.info.num_pairs,...
    rec2_path, rec2.info.num_pairs);

mkdir(rec_out_path);
movefile(merged_rec, rec_out_path);

ds = DaySummary([], rec_out_path);
ds.set_labels(1:rec1.info.num_pairs);

M = load_movie(movie_filename);
initial_cell_count = rec1.info.num_pairs;
clearvars -except ds M merge_dirname initial_cell_count;

cprintf('blue', 'Please classify "merge/concat"...\n');
classify_cells(ds, M);
cprintf('blue', 'Gained %d cells!\n', ds.num_classified_cells - initial_cell_count);

%% After classification, generate combined LS traces
clearvars -except merge_dirname ds;
num_cells = ds.num_classified_cells;

switch dirname
    case '1P'
        movie_filename = get_most_recent_file('', '*_dff.hdf5');
        
    case '2P'
        movie_filename = get_most_recent_file('', '*_zsc.hdf5');
end

recname_ls = backapply_filters(ds, movie_filename, 'ls', 'fix', 'percentile');
path_to_merge = fullfile(merge_dirname, 'ls');
mkdir(path_to_merge);
movefile(recname_ls, path_to_merge);
class_file = generate_class_file(num_cells);
movefile(class_file, path_to_merge);
cprintf('blue', 'Least squares traces computation complete!\n');