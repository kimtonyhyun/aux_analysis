% clear all;

dff_movie = dir('*.hdf5');
dff_movie = dff_movie.name;
fprintf('%s: Loading "%s"...\n', datestr(now), dff_movie);
M = load_movie(dff_movie);


%% Generate Rec files from the match results

name2date = @(x) x(end-1:end);
dataset_name = dirname;
dataset_date = name2date(dataset_name);

matches = dir(sprintf('match_%s_*.mat', dataset_date));
num_matches = length(matches);

for k = 1:num_matches
    match_name = matches(k).name;
    match_data = load(matches(k).name);
    
    [~, match_name] = fileparts(match_name); % Skip the extension
    match_date = name2date(match_name);
    
    [~, rec_savename] = get_dff_traces(match_data.info.filters_2to1.im, M);
    
    rec_dirname = fullfile('imports', sprintf('from_%s', match_date));
    mkdir(rec_dirname);
    movefile(rec_savename, rec_dirname);
end

%% Resolve the incoming filters prior to sorting

imported_datasets = dir('imports/from_*');
num_imports = length(imported_datasets);
imports = cell(num_imports, 2); % [Name(string) DaySummary]

for k = 1:num_imports
    import_name = imported_datasets(k).name;
    imports{k,1} = import_name;
    imports{k,2} = DaySummary([], fullfile('imports', import_name));
end
% clear imported_datasets import_name k;

%%

ds = DaySummary([], 'cm/clean'); % Original rec. FIXME: Hard-coded
md = create_merge_md([{ds}; imports(:,2)]);

%%

res_list = resolve_merged_recs(md, 'norm_traces',...
                'movie', M,...
                'names', [{'Original'}; imports(:,1)]);
save_resolved_recs(res_list, md);

%%
% Final steps:
%   1) Copy labels from original rec to the resolved rec
%   2) Manually classify remaining cells (i.e. newly imported cells)