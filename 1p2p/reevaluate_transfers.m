clear all;

switch dirname
    case '1P'
        movie_filename = get_most_recent_file('', '*_dff_ti4.hdf5');
        
    otherwise % Assume 2P
        movie_filename = get_most_recent_file('', '*_zsc_ti4.hdf5');

end
M = load_movie(movie_filename);

%% Re-evaluate 1P:2P transferred filters

% First-pass cell extraction results
rec1_path = 'ext1/ls_ti4';
rec1 = load(get_most_recent_file(rec1_path, 'rec_*.mat'));
initial_cell_count = rec1.info.num_pairs;

% Load the previously concatenated list of cells
ds = DaySummary('', 'merge/concat');
ds.reset_labels;
ds.set_labels(1:initial_cell_count);

classify_cells(ds, M);
cprintf('blue', 'Gained %d cells!\n', ds.num_classified_cells - initial_cell_count);

%% Recompute least squares traces

switch dirname
    case '1P'
        movie_filename = get_most_recent_file('', '*_dff.hdf5');
        
    otherwise
        movie_filename = get_most_recent_file('', '*_zsc.hdf5');
end

[rec_file, class_file] = backapply_filters(ds, movie_filename, 'ls', 'fix', 'percentile', 'generate_class');

path_to_merge = 'merge-repeat/ls';
mkdir(path_to_merge);
movefile(rec_file, path_to_merge);
movefile(class_file, path_to_merge);
cprintf('blue', 'Least squares traces computation complete!\n');

%% Evaluate post-merge 1P/2P filters

clear all;

ds = DaySummary([], '1P/merge-repeat/ls');
ds2 = DaySummary([], '2P/merge-repeat/ls');

load('match_pre.mat', 'info'); % Contains affine transform result

fps = 25.4;
[matched, non_matched] = match_1p2p(ds, ds2, info.tform, fps);
cprintf('blue', 'Found %d matched cells between 1P and 2P\n', size(matched,1));

save('corrlist-repeat', 'matched', 'non_matched');
