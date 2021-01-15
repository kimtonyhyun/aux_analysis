%% PART 1: Initial assessment and filter transfer across 1P-2P
%------------------------------------------------------------

clear all;

path_to_dataset1 = '1P';
path_to_dataset2 = '2P';

ds = DaySummary([], fullfile(path_to_dataset1, 'ext1/proj'));
ds2 = DaySummary([], fullfile(path_to_dataset2, 'ext1/proj'));

%% Temporal correlations facilitate identification of matched cells

corrlist_1p2p = compute_corrlist(ds, ds2);
browse_corrlist(corrlist_1p2p, ds, ds2, 'names', {path_to_dataset1, path_to_dataset2}, 'zsc');

%% Perform spatial alignment

close all;

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

close all;

merge_dirname = 'merge-sl4';

cprintf('blue', 'Transferring filters from 2P to 1P...\n');
filename_1p = get_most_recent_file(path_to_dataset1, '*.hdf5');
[~, recname_2to1] = get_dff_traces(info.filters_2to1.im, filename_1p, 'ls', 'fix', 'percentile');
path_to_merge = fullfile(path_to_dataset1, merge_dirname, 'from_2p');
mkdir(path_to_merge);
movefile(recname_2to1, path_to_merge);

cprintf('blue', 'Transferring filters from 1P to 2P...\n');
filename_2p = get_most_recent_file(path_to_dataset2, '*_zsc.hdf5');
[~, recname_1to2] = get_dff_traces(info.filters_1to2.im, filename_2p, 'ls', 'fix', 'percentile');
path_to_merge = fullfile(path_to_dataset2, merge_dirname, 'from_1p');
mkdir(path_to_merge);
movefile(recname_1to2, path_to_merge);

cprintf('blue', 'Done with transfers!\n');

%% PART 2: Classify 1P-2P merged filters
%------------------------------------------------------------

clearvars -except merge_dirname;
close all;

switch dirname
    case '1P'
        rec1_path = 'ext1/ls_ti4';
%         rec2_path = 'merge/from_2p';
        rec2_path = fullfile(merge_dirname, 'from_2p');
        movie_filename = get_most_recent_file('', '*.hdf5');
        
    otherwise % Assume 2P
        rec1_path = 'ext1/ls';
%         rec2_path = 'merge/from_1p';
        rec2_path = fullfile(merge_dirname, 'from_1p');
        movie_filename = get_most_recent_file('', '*_zsc.hdf5');
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
clearvars -except ds M merge_dirname;

cprintf('blue', 'Please classify "merge/concat"...\n');
classify_cells(ds, M);

%% After classification, generate combined LS traces

[~, recname_ls] = get_dff_traces(ds, M, 'ls', 'fix', 'percentile');
path_to_merge = fullfile(merge_dirname, 'ls');
mkdir(path_to_merge);
movefile(recname_ls, path_to_merge);
ds = DaySummary([], path_to_merge);
ds.set_labels;
class_file = ds.save_class;
movefile(class_file, path_to_merge);
