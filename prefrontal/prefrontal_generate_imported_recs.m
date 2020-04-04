clear all;

zsc_movie = dir('*.hdf5');
zsc_movie = zsc_movie.name;
fprintf('%s: Loading "%s"...\n', datestr(now), zsc_movie);
M = load_movie(zsc_movie);

dataset_name = dirname;
dataset_date = dataset_name(end-1:end);

matches = dir(sprintf('match_%s_*.mat', dataset_date));
num_matches = length(matches);

%%

for k = 1:num_matches
    match_name = matches(k).name;
    match_data = load(matches(k).name);
    
    [~, match_name] = fileparts(match_name); % Skip the extension
    match_date = match_name(end-1:end);
    
    [~, rec_savename] = get_dff_traces(match_data.info.filters_2to1.im, M);
    
    rec_dirname = sprintf('from_%s', match_date);
    mkdir(rec_dirname);
    movefile(rec_savename, rec_dirname);
end