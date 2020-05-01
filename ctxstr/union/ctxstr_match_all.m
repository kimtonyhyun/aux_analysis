clear;

mouse_name = 'oh05';
region = 'ctx'; % Either 'ctx' or 'str'
get_id = @(x) x(end-3:end);

[ds_list, num_datasets] = load_all_ds(mouse_name,...
    fullfile(region, 'cnmf1/iter2'), get_id);

%% Select primary day, and match all others to it

primary_day = 1;
fprintf('%s: Selected "%s" as primary day\n', datestr(now), ds_list{primary_day,1});

ds1 = ds_list{primary_day,2};
k = primary_day + 1;

%% Run alignment

close all;

ds2 = ds_list{k,2};
[m_1to2, m_2to1, info] = run_alignment(ds1, ds2, 'num_points', 4);

%% Happy with alignment? Save and move on

savename = sprintf('match_%s_%s_%s.mat', region, ds_list{primary_day,1}, ds_list{k,1});
save(savename, 'm_1to2', 'm_2to1', 'info');
fprintf('%s: Saved "%s"\n', datestr(now), savename);

% Also save the "reverse" match file
[m_1to2, m_2to1, info] = reverse_alignment_outputs(m_1to2, m_2to1, info);

savename = sprintf('match_%s_%s_%s.mat', region, ds_list{k,1}, ds_list{primary_day,1});
save(savename, 'm_1to2', 'm_2to1', 'info');
fprintf('%s: Saved "%s"\n', datestr(now), savename);

k = k + 1;