clear all;

mouse_name = 'oh12';

datasets = dir(sprintf('%s-*', mouse_name));
num_datasets = length(datasets);
fprintf('%s: For "%s" found %d datasets\n',...
    datestr(now), mouse_name, num_datasets);

ds_list = cell(num_datasets, 2); % [Name(string) DaySummary]
for k = 1:num_datasets
    dataset_name = datasets(k).name;
    path_to_rec = sprintf('%s/cnmf1/iter2', dataset_name); % FIXME: Assumed path
    
    dataset_date = dataset_name(end-3:end); % FIXME: Assumed formatting
    ds_list{k,1} = dataset_date;
    ds_list{k,2} = DaySummary([], path_to_rec);
end
clear k dataset_name dataset_date path_to_rec;

%% Select primary day, and match all others to it

primary_day = 8;
fprintf('%s: Selected "%s" as primary day\n', datestr(now), ds_list{primary_day,1});
other_days = setdiff(1:num_datasets, primary_day);

ds1 = ds_list{primary_day,2};
k = 1;

%% Run alignment

close all;

other_day = other_days(k);
ds2 = ds_list{other_day,2};
[m_1to2, m_2to1, info] = run_alignment(ds1, ds2, 'num_points', 5);

%% Happy with alignment? Save and move on

savename = sprintf('match_%s_%s.mat', ds_list{primary_day,1}, ds_list{other_day,1});
save(savename, 'm_1to2', 'm_2to1', 'info');
fprintf('%s: Saved "%s"\n', datestr(now), savename);
k = k + 1;