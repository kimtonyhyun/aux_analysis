clear all; close all;

dataset_name = dirname;
fprintf('%s: Preprocessing "%s"...\n', datestr(now), dataset_name);

str_stem = sprintf('%s-str', dataset_name);

%% Convert to HDF5

% str
str_source = 'str_00001.tif';
M = load_scanimage_tif(str_source);

M1 = M(:,:,2:4:end); % rDA movie (i.e. 1064 nm / red ch)
F = compute_fluorescence_stats(M1);
M1 = M1 - int16(mean(F(:,1)));
save_movie_to_hdf5(M1, sprintf('%s-rda.hdf5', str_stem));

M2 = M(:,:,3:4:end); % GCaMP movie (i.e. 920 nm / green ch)
F = compute_fluorescence_stats(M2);
M2 = M2 - int16(mean(F(:,1)));
save_movie_to_hdf5(M2, sprintf('%s-gcamp.hdf5', str_stem));

clear str_source;
fprintf('<strong>%s: DONE with HDF5 conversion!</strong>\n', datestr(now));

%% Meancorr

% str
meancorr_movie([str_stem '-gcamp.hdf5'], '');
meancorr_movie([str_stem '-rda.hdf5'], '');

fprintf('<strong>%s: DONE with meancorr_movie!</strong>\n', datestr(now));

%% Compute and store fluorescence stats

F_rda = compute_fluorescence_stats([str_stem '-rda.hdf5']);
F_rda_uc = compute_fluorescence_stats([str_stem '-rda_uc.hdf5']);

F_gcamp = compute_fluorescence_stats([str_stem '-gcamp.hdf5']);
F_gcamp_uc = compute_fluorescence_stats([str_stem '-gcamp_uc.hdf5']);

save('fluorescences.mat', 'F_rda', 'F_rda_uc', 'F_gcamp', 'F_gcamp_uc');

delete([str_stem '-rda.hdf5']);
delete([str_stem '-gcamp.hdf5']);

fprintf('<strong>%s: DONE with full-field fluorescence computations!</strong>\n', datestr(now));

%% (Optional) Visualize full-field fluorescence

bdata = load('ctxstr.mat');
fdata = load('fluorescences.mat');

t_rda = bdata.str.frame_times(1:2:end);
t_gcamp = bdata.str.frame_times(2:2:end);

t_lims = [0 t_gcamp(end)];
plot(t_lims, [1 1], 'k:');
hold on;
plot(t_rda, fdata.F_rda_uc(:,2), 'm');
plot(t_gcamp, fdata.F_gcamp_uc(:,2), 'Color', [0 0.5 0]);

y_lims = [0.9 1.1];
plot_vertical_lines(bdata.behavior.us_times, y_lims, 'b-');
plot(bdata.behavior.lick_times,...
     (y_lims(2)-0.05*diff(y_lims))*ones(size(bdata.behavior.lick_times)),...
     'k.');
hold off;
xlim(t_lims);
ylim(y_lims);
set(gca, 'TickLength', [0 0]);
set(gca, 'FontSize', 18);
xlabel('Time (s)');
ylabel({'Full-field', 'fluorescences (a.u.)'});
title(dataset_name);
zoom xon;

%% Normcorre

% str
run_normcorre([str_stem '-gcamp_uc.hdf5'], '');
% delete([str_stem '_uc.hdf5']);

bin_movie_in_time([str_stem '-gcamp_uc_nc.hdf5'], '', 12);

fprintf('<strong>%s: DONE with run_normcorre!</strong>\n', datestr(now));