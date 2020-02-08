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

delete(ctx_source); clear ctx_source;

% str
str_source = 'str_00001.tif';

% slice 1
Mg = load_scanimage_tif2(str_source, 'frames', 1:8:96000);
Fg = compute_fluorescence_stats(Mg);
Mg = Mg - int16(mean(Fg(:,1)));
save_movie_to_hdf5(Mg, [str_stem '-sl1.hdf5']);
clear Mg Fg;

Mr = load_scanimage_tif2(str_source, 'frames', 2:8:96000);
Fr = compute_fluorescence_stats(Mr);
Mr = Mr - int16(mean(Fr(:,1)));
save_movie_to_hdf5(Mr, [str_stem '-sl1-tdt.hdf5']);
clear Mr Fr;

% slice 2
Mg = load_scanimage_tif2(str_source, 'frames', 3:8:96000);
Fg = compute_fluorescence_stats(Mg);
Mg = Mg - int16(mean(Fg(:,1)));
save_movie_to_hdf5(Mg, [str_stem '-sl2.hdf5']);
clear Mg Fg;

Mr = load_scanimage_tif2(str_source, 'frames', 4:8:96000);
Fr = compute_fluorescence_stats(Mr);
Mr = Mr - int16(mean(Fr(:,1)));
save_movie_to_hdf5(Mr, [str_stem '-sl2-tdt.hdf5']);
clear Mr Fr;

% slice 3
Mg = load_scanimage_tif2(str_source, 'frames', 5:8:96000);
Fg = compute_fluorescence_stats(Mg);
Mg = Mg - int16(mean(Fg(:,1)));
save_movie_to_hdf5(Mg, [str_stem '-sl3.hdf5']);
clear Mg Fg;

Mr = load_scanimage_tif2(str_source, 'frames', 6:8:96000);
Fr = compute_fluorescence_stats(Mr);
Mr = Mr - int16(mean(Fr(:,1)));
save_movie_to_hdf5(Mr, [str_stem '-sl3-tdt.hdf5']);
clear Mr Fr;

delete(str_source); clear str_source;

fprintf('<strong>%s: DONE with HDF5 conversion!</strong>\n', datestr(now));

%% Meancorr

% ctx
meancorr_movie([ctx_stem '.hdf5'], '');
meancorr_movie([ctx_stem '-tdt.hdf5'], '');

delete([ctx_stem '.hdf5']);
delete([ctx_stem '-tdt.hdf5']);

% str

% slice 1
meancorr_movie([str_stem '-sl1.hdf5'], '');
meancorr_movie([str_stem '-sl1-tdt.hdf5'], '');

delete([str_stem '-sl1.hdf5']);
delete([str_stem '-sl1-tdt.hdf5']);

% slice 2
meancorr_movie([str_stem '-sl2.hdf5'], '');
meancorr_movie([str_stem '-sl2-tdt.hdf5'], '');

delete([str_stem '-sl2.hdf5']);
delete([str_stem '-sl2-tdt.hdf5']);

% slice 3
meancorr_movie([str_stem '-sl3.hdf5'], '');
meancorr_movie([str_stem '-sl3-tdt.hdf5'], '');

delete([str_stem '-sl3.hdf5']);
delete([str_stem '-sl3-tdt.hdf5']);

fprintf('<strong>%s: DONE with meancorr_movie!</strong>\n', datestr(now));

%% Normcorre

% ctx
run_normcorre([ctx_stem '-tdt_uc.hdf5'], '');
A = compute_mean_image([ctx_stem '-tdt_uc_nc.hdf5']);
save([ctx_stem '-tdt.mat'], 'A');
figure; imagesc(A, [0.3 3.5]); truesize; colormap gray;
title([ctx_stem '-tdt']);
print('-dpng', [ctx_stem '-tdt']);

delete([ctx_stem '-tdt_uc.hdf5']);
delete([ctx_stem '-tdt_uc_nc.hdf5']);

load([ctx_stem '-tdt_uc_nc.mat']);
apply_shifts([ctx_stem '_uc.hdf5'], shifts, info.nc_options);

delete([ctx_stem '_uc.hdf5']);

bin_movie_in_time([ctx_stem '_uc_nc.hdf5'], '', 8); % for visualization

% str

% slice 1
run_normcorre([str_stem '-sl1-tdt_uc.hdf5'], '');
A = compute_mean_image([str_stem '-sl1-tdt_uc_nc.hdf5']);
save([str_stem '-sl1-tdt.mat'], 'A');
figure; imagesc(A, [0.3 3.5]); truesize; colormap gray;
title([str_stem '-sl1-tdt']);
print('-dpng', [str_stem '-sl1-tdt']);

delete([str_stem '-sl1-tdt_uc.hdf5']);
delete([str_stem '-sl1-tdt_uc_nc.hdf5']);

load([str_stem '-sl1-tdt_uc_nc.mat']);
apply_shifts([str_stem '-sl1_uc.hdf5'], shifts, info.nc_options);

delete([str_stem '-sl1_uc.hdf5']);

bin_movie_in_time([str_stem '-sl1_uc_nc.hdf5'], '', 3);

% slice 2
run_normcorre([str_stem '-sl2-tdt_uc.hdf5'], '');
A = compute_mean_image([str_stem '-sl2-tdt_uc_nc.hdf5']);
save([str_stem '-sl2-tdt.mat'], 'A');
figure; imagesc(A, [0.3 3.5]); truesize; colormap gray;
title([str_stem '-sl2-tdt']);
print('-dpng', [str_stem '-sl2-tdt']);

delete([str_stem '-sl2-tdt_uc.hdf5']);
delete([str_stem '-sl2-tdt_uc_nc.hdf5']);

load([str_stem '-sl2-tdt_uc_nc.mat']);
apply_shifts([str_stem '-sl2_uc.hdf5'], shifts, info.nc_options);

delete([str_stem '-sl2_uc.hdf5']);

bin_movie_in_time([str_stem '-sl2_uc_nc.hdf5'], '', 3);

% slice 3
run_normcorre([str_stem '-sl3-tdt_uc.hdf5'], '');
A = compute_mean_image([str_stem '-sl3-tdt_uc_nc.hdf5']);
save([str_stem '-sl3-tdt.mat'], 'A');
figure; imagesc(A, [0.3 3.5]); truesize; colormap gray;
title([str_stem '-sl3-tdt']);
print('-dpng', [str_stem '-sl3-tdt']);

delete([str_stem '-sl3-tdt_uc.hdf5']);
delete([str_stem '-sl3-tdt_uc_nc.hdf5']);

load([str_stem '-sl3-tdt_uc_nc.mat']);
apply_shifts([str_stem '-sl3_uc.hdf5'], shifts, info.nc_options);

delete([str_stem '-sl3_uc.hdf5']);

bin_movie_in_time([str_stem '-sl3_uc_nc.hdf5'], '', 3);

fprintf('<strong>%s: DONE with run_normcorre!</strong>\n', datestr(now));