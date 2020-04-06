clear;

dff_movie = dir('*.hdf5');
dff_movie = dff_movie.name;
fprintf('%s: Loading "%s"...\n', datestr(now), dff_movie);
M = load_movie(dff_movie);

%% Generate Rec files from the match results

get_id = @(x) x(end-1:end);
dataset_name = dirname;
dataset_id = get_id(dataset_name);

matches = dir(sprintf('match_%s_*.mat', dataset_id));
num_matches = length(matches);

for k = 1:num_matches
    match_name = matches(k).name;
    match_data = load(matches(k).name);
    
    [~, match_name] = fileparts(match_name); % Skip the extension
    match_date = get_id(match_name);
    
    [~, rec_savename] = get_dff_traces(match_data.info.filters_2to1.im, M);
    
    rec_dirname = fullfile('imports', sprintf('from_%s', match_date));
    mkdir(rec_dirname);
    movefile(rec_savename, rec_dirname);
end

%% Resolve the incoming filters prior to sorting

[imports, num_imports] = load_all_ds('imports/from_');

ds = DaySummary([], 'cm/clean'); % Original rec. FIXME: Hard-coded
num_orig_cells = ds.num_classified_cells;
md = create_merge_md([{ds}; imports(:,2)]);

%%

res_list = resolve_merged_recs(md, M,...
                'norm_traces',...
                'names', [{'Original'}; imports(:,1)]);
save_resolved_recs(res_list, md);

% Move the output rec into the following subdirectory: 'union/resolved'

%%

% Final steps:
%   1) Copy labels from original rec to the resolved rec
%   2) Manually classify remaining cells (i.e. newly imported cells)

clearvars -except num_orig_cells M;

dsr = DaySummary('', 'union/resolved');

% The first cells in the resolved DS are taken directly from the original
% DaySummary. Sort the rest!
dsr.set_labels(1:num_orig_cells);

classify_cells(dsr, M);