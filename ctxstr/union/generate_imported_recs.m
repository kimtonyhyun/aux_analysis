clear all;

M = load_movie('oh12-0126-ctx_uc_nc_ti8_zsc.hdf5');

dataset_name = dirname;
dataset_date = dataset_name(end-3:end);

matches = dir(sprintf('match_%s_*.mat', dataset_date));
num_matches = length(matches);

%%

for k = 1:num_matches
    match_name = matches(k).name;
    match_data = load(matches(k).name);
    
    [~, match_name] = fileparts(match_name); % Skip the extension
    match_date = match_name(end-3:end);
    
    [~, rec_savename] = get_dff_traces(match_data.info.filters_2to1.im, M, 'fix');
    
    rec_dirname = sprintf('from_%s', match_date);
    mkdir(rec_dirname);
    movefile(rec_savename, rec_dirname);
end