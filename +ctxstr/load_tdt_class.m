function tdt = load_tdt_class(path_to_rec)

tdt_filename = get_most_recent_file(path_to_rec, 'tdt_*.mat');
tdt = load(tdt_filename);