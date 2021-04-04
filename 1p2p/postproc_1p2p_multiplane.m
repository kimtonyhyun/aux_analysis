%%
% Basically identical to "postproc_1p2p" but with filenames that are
% appropriate for 1P:multiplane 2P analysis.

clear all;

path_to_dataset1 = '1P';
path_to_dataset2 = '2P/sl5_d300';

% Path names depend on the number of planes in multiplane recording.
num_planes = 5;

ds = DaySummary([], fullfile(path_to_dataset1,...
                             sprintf('ext1/ls_ti%d', num_planes)));
ds2 = DaySummary([], fullfile(path_to_dataset2, 'ext1/ls'));

%% Temporal correlations facilitate identification of matched cells

corrlist_1p2p = compute_corrlist(ds, ds2);
browse_corrlist(corrlist_1p2p, ds, ds2, 'names', {path_to_dataset1, path_to_dataset2}, 'zsc');

%% Perform spatial alignment
% Note that while we don't use 'm_XtoY' as part of the matching process, we
% _do_ need to compute it, as the output of the matching procedure
% determines which filters are transferred across modalities (i.e. only
% unmatched filters are transferred).

close all;

% inds: [N x 2] list of cell indices where each row is a matched cell.
[m_1to2, m_2to1, info] = run_alignment(ds, ds2, 'alignment_cell_inds', inds); %#ok<*ASGLU>
save('match_pre', 'm_1to2', 'm_2to1', 'info', '-v7.3');

%% Save image of the spatial alignment

dataset_name = dirname;
num_cells_1p = ds.num_classified_cells;
num_cells_2p = ds2.num_classified_cells;

title_str = sprintf('%s (PRE-merge)\n%s (%d cells; blue) vs. %s (%d cells; red)',...
    dataset_name, path_to_dataset1, num_cells_1p, path_to_dataset2, num_cells_2p);
title(title_str, 'Interpreter', 'none');
set(gca, 'FontSize', 18);
print('-dpng', 'overlay_pre');

%% Transfer cell filters across modalities
% Just needs 'path_to_datasetX' and 'info' from run_alignment

close all;

merge_dirname = 'merge';

cprintf('blue', 'Transferring filters from 2P to 1P...\n');
filename_1p = get_most_recent_file(path_to_dataset1,...
                                   sprintf('*_dff_ti%d.hdf5', num_planes));
recname_2to1 = backapply_filters(info.filters_2to1.im, filename_1p, 'fix', 'percentile');
path_to_merge = fullfile(path_to_dataset1, merge_dirname, 'from_2p');
mkdir(path_to_merge);
movefile(recname_2to1, path_to_merge);

cprintf('blue', 'Transferring filters from 1P to 2P...\n');
filename_2p = get_most_recent_file(path_to_dataset2, '*_zsc.hdf5');
recname_1to2 = backapply_filters(info.filters_1to2.im, filename_2p, 'fix', 'percentile');
path_to_merge = fullfile(path_to_dataset2, merge_dirname, 'from_1p');
mkdir(path_to_merge);
movefile(recname_1to2, path_to_merge);

cprintf('blue', 'Done with transfers!\n');

%%
%------------------------------------------------------------
% PART 2: Classify 1P-2P merged filters
%------------------------------------------------------------

clearvars -except merge_dirname num_planes;
close all;

switch dirname
    case '1P'
        rec1_path = sprintf('ext1/ls_ti%d', num_planes);
        rec2_path = fullfile(merge_dirname, 'from_2p');
        movie_filename = get_most_recent_file('',...
                            sprintf('*_dff_ti%d.hdf5', num_planes));
        
    otherwise % Assume 2P
        rec1_path = 'ext1/ls';
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
initial_cell_count = rec1.info.num_pairs;
clearvars -except ds M merge_dirname initial_cell_count num_planes;

cprintf('blue', 'Please classify "merge/concat"...\n');
classify_cells(ds, M);
cprintf('blue', 'Gained %d cells!\n', ds.num_classified_cells - initial_cell_count);

%% After classification, generate combined LS traces
clearvars -except merge_dirname ds num_planes;

switch dirname
    case '1P'
        movie_filename = get_most_recent_file('',...
            sprintf('*_dff_ti%d.hdf5', num_planes));
        path_to_merge = fullfile(merge_dirname,...
            sprintf('ls_ti%d', num_planes));

    otherwise
        movie_filename = get_most_recent_file('', '*_zsc.hdf5');
        path_to_merge = fullfile(merge_dirname, 'ls');
end

[rec_file, class_file] = backapply_filters(ds, movie_filename, 'ls', 'fix', 'percentile', 'generate_class');
mkdir(path_to_merge);
movefile(rec_file, path_to_merge);
movefile(class_file, path_to_merge);
cprintf('blue', 'Least squares traces computation complete!\n');