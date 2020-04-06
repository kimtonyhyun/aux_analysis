clear;

mouse_name = 'c11m1';
get_id = @(x) x(end-1:end);

[ds_list, num_datasets] = load_all_ds(mouse_name, 'cm/clean', get_id);

%% Select primary day, and match all others to it

primary_day = 6;
fprintf('%s: Selected "%s" as primary day\n', datestr(now), ds_list{primary_day,1});
other_days = setdiff(1:num_datasets, primary_day);

ds1 = ds_list{primary_day,2};
k = 1;

%% Run alignment

close all;

other_day = other_days(k);
ds2 = ds_list{other_day,2};
[m_1to2, m_2to1, info] = run_alignment(ds1, ds2, 'num_points', 4);

%% Happy with alignment? Save and move on

savename = sprintf('match_%s_%s.mat', ds_list{primary_day,1}, ds_list{other_day,1});
save(savename, 'm_1to2', 'm_2to1', 'info');
fprintf('%s: Saved "%s"\n', datestr(now), savename);
k = k + 1;