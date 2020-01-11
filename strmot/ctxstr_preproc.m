clear all; close all;

dataset_name = dirname;
fprintf('%s: Preprocessing "%s"...\n', datestr(now), dataset_name);

ctx_stem = sprintf('%s-ctx', dataset_name);
str_stem = sprintf('%s-str', dataset_name);

%% Convert to HDF5

% ctx
ctx_source = 'ctx_00001.tif';

Mg = load_scanimage_tif2(ctx_source, 'odd'); % Green channel
Fg = compute_fluorescence_stats(Mg);
Mg = Mg - int16(mean(Fg(:,1)));
save_movie_to_hdf5(Mg, [ctx_stem '.hdf5']);
clear Mg Fg;

Mr = load_scanimage_tif2(ctx_source, 'even'); % Red channel
Fr = compute_fluorescence_stats(Mr);
Mr = Mr - int16(mean(Fr(:,1)));
save_movie_to_hdf5(Mr, [ctx_stem '-tdt.hdf5']);
clear Mr Fr;

% str
str_source = 'str_00001.tif';

Mg = load_scanimage_tif2(str_source, 'odd'); % Green channel
Fg = compute_fluorescence_stats(Mg);
Mg = Mg - int16(mean(Fg(:,1)));
save_movie_to_hdf5(Mg, [str_stem '.hdf5']);
clear Mg Fg;

Mr = load_scanimage_tif2(str_source, 'even'); % Red channel
Fr = compute_fluorescence_stats(Mr);
Mr = Mr - int16(mean(Fr(:,1)));
save_movie_to_hdf5(Mr, [str_stem '-tdt.hdf5']);
clear Mr Fr;

fprintf('%s: DONE with HDF5 conversion!\n', datestr(now));

%% Meancorr

% ctx
meancorr_movie([ctx_stem '.hdf5'], '');
meancorr_movie([ctx_stem '-tdt.hdf5'], '');

% str
meancorr_movie([str_stem '.hdf5'], '');
meancorr_movie([str_stem '-tdt.hdf5'], '');

fprintf('%s: DONE with meancorr_movie!\n', datestr(now));

%% Normcorre

% ctx
run_normcorre([ctx_stem '-tdt_uc.hdf5'], '');
A = compute_mean_image([ctx_stem '-tdt_uc_nc.hdf5']);
save([ctx_stem '-tdt.mat'], A);

load([ctx_stem '-tdt_uc_nc.mat']);
apply_shifts([ctx_stem '_uc.hdf5'], shifts, info.nc_options);

% str
run_normcorre([str_stem '-tdt_uc.hdf5'], '');
A = compute_mean_image([str_stem '-tdt_uc_nc.hdf5']);
save([str_stem '-tdt.mat'], A);

load([str_stem '-tdt_uc_nc.mat']);
apply_shifts([str_stem '_uc.hdf5'], shifts, info.nc_options);
bin_movie_in_time([str_stem '_uc_nc.hdf5'], '', 12);

fprintf('%s: DONE with run_normcorre!\n', datestr(now));