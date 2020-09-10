%% Post-processing: Merge 1P and 2P filters

clear all;

ds = DaySummary([], '1P/cm_ext1/ls');
ds2 = DaySummary([], '2P/ext1/ls');

%% Temporal correlations facilitate identification of matched cells

corrlist_1p2p = compute_corrlist(ds, ds2);
browse_corrlist(corrlist_1p2p, ds, ds2, 'names', {'1P', '2P'}, 'zsc');

%% Perform spatial alignment

[m_1to2, m_2to1, info] = run_alignment(ds, ds2); %#ok<*ASGLU>
save('match_pre', 'm_1to2', 'm_2to1', 'info');

%% Save image of the initial spatial alignment

dataset_name = dirname;
num_cells_1p = ds.num_classified_cells;
num_cells_2p = ds2.num_classified_cells;

title_str = sprintf('%s (PRE-merge)\n1P (%d cells; blue) vs. 2P (%d cells; red)',...
    dataset_name, num_cells_1p, num_cells_2p);
title(title_str);
set(gca, 'FontSize', 18);
print('-dpng', 'overlay_pre');

%% Transfer cell filters across modalities

cprintf('blue', 'Transferring filters from 2P to 1P...\n');
filename_1p = get_most_recent_file('1P', '*_dff.hdf5');
[~, recname_2to1] = get_dff_traces(info.filters_2to1.im, filename_1p, 'ls', 'fix', 'percentile');
mkdir 1P/merge/from_2p
movefile(recname_2to1, '1P/merge/from_2p');

cprintf('blue', 'Transferring filters from 1P to 2P...\n');
filename_2p = get_most_recent_file('2P', '*_zsc.hdf5');
[~, recname_1to2] = get_dff_traces(info.filters_1to2.im, filename_2p, 'ls', 'fix', 'percentile');
mkdir 2P/merge/from_1p
movefile(recname_1to2, '2P/merge/from_1p');

cprintf('blue', 'Done with transfers!\n');

%% Classify 1P-2P merged filters

clear all;

switch dirname
    case '1P'
        rec1_path = 'cm_ext1/ls';
        rec2_path = 'merge/from_2p';
        rec_out_path = 'merge/concat';
        movie_filename = get_most_recent_file('', '*_dff.hdf5');
        
    case '2P'
        rec1_path = 'ext1/ls';
        rec2_path = 'merge/from_1p';
        rec_out_path = 'merge/concat';
        movie_filename = get_most_recent_file('', '*_zsc.hdf5');
end

rec1 = load(get_most_recent_file(rec1_path, 'rec_*.mat'));
rec2 = load(get_most_recent_file(rec2_path, 'rec_*.mat'));

filters = cat(3, rec1.filters, rec2.filters);
traces = cat(2, rec1.traces, rec2.traces);

info.type = 'merge';
info.num_pairs = rec1.info.num_pairs + rec2.info.num_pairs;
info.merge = {rec1_path, rec2_path};

merged_rec = save_rec(info, filters, traces);
fprintf('Merged "%s" (%d cells) and "%s" (%d cells)\n',...
    rec1_path, rec1.info.num_pairs,...
    rec2_path, rec2.info.num_pairs);

mkdir(rec_out_path);
movefile(merged_rec, rec_out_path);

ds = DaySummary([], rec_out_path);
ds.set_labels(1:rec1.info.num_pairs);

M = load_movie(movie_filename);
clearvars -except ds M;

classify_cells(ds, M);

%% After classification, generate combined LS traces

[~, recname_ls] = get_dff_traces(ds, M, 'ls', 'fix', 'percentile');
mkdir merge/ls
movefile(recname_ls, 'merge/ls');
ds = DaySummary([], 'merge/ls');
ds.set_labels;
class_file = ds.save_class;
movefile(class_file, 'merge/ls');

%% Match post-merge 1P/2P filters

clear all;

ds = DaySummary([], '1P/merge/ls');
ds2 = DaySummary([], '2P/merge/ls');

%% Perform spatial alignment

[m_1to2, m_2to1, info] = run_alignment(ds, ds2);
save('match_post', 'm_1to2', 'm_2to1', 'info');

%% Save image of the initial spatial alignment

dataset_name = dirname;
num_cells_1p = ds.num_classified_cells;
num_cells_2p = ds2.num_classified_cells;

title_str = sprintf('%s (POST-merge)\n1P (%d cells; blue) vs. 2P (%d cells; red)',...
    dataset_name, num_cells_1p, num_cells_2p);
title(title_str);
set(gca, 'FontSize', 18);
print('-dpng', 'overlay_post');

