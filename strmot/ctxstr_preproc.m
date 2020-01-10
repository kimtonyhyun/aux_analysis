clear all; close all;

dataset_name = dirname;
fprintf('%s: Preprocessing "%s"...\n', datestr(now), dataset_name);

ctx_stem = sprintf('%s-ctx', dataset_name);

%% Ctx: Convert to HDF5

source = 'ctx_00001.tif';
Mg = load_scanimage_tif2(source, 'odd'); % Green channel
Fg = compute_fluorescence_stats(Mg);
Mg = Mg - int16(mean(Fg(:,1)));
save_movie_to_hdf5(Mg, [ctx_stem '.hdf5']);
clear Mg Fg;

Mr = load_scanimage_tif2(source, 'even'); % Red channel
Fr = compute_fluorescence_stats(Mr);
Mr = Mr - int16(mean(Fr(:,1)));
save_movie_to_hdf5(Mr, [ctx_stem '-tdt.hdf5']);
clear Mr Fr;

fprintf('%s: DONE with HDF5 conversion!\n', datestr(now));

%% Ctx: Meancorr

meancorr_movie([ctx_stem '.hdf5'], '');
meancorr_movie([ctx_stem '-tdt.hdf5'], '');

fprintf('%s: DONE with meancorr_movie!\n', datestr(now));

%% Ctx: Normcorre

run_normcorre([ctx_stem '-tdt_uc.hdf5'], '');
load([ctx_stem '-tdt_uc_nc.mat']);
apply_shifts([ctx_stem '_uc.hdf5'], shifts, info.nc_options);

fprintf('%s: DONE with run_normcorre!\n', datestr(now));