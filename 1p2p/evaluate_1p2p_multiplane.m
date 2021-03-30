%% Evaluate post-merge 1P/2P filters

clear all;

path_to_dataset1 = '1P/merge/ls_ti6';
paths_to_dataset2 = {'2P/sl2_d100/ext1/ls';
                     '2P/sl3_d150/ext1/ls';
                     '2P/sl4_d200/merge/ls';
                     '2P/sl5_d250/ext1/ls';
                     '2P/sl6_d300/ext1/ls';
                     '2P/sl1_d350/ext1/ls';
                    };
num_slices = length(paths_to_dataset2);

ds1 = DaySummary([], path_to_dataset1);
ds2 = cell(num_slices, 1);
for k = 1:num_slices
    ds2{k} = DaySummary([], paths_to_dataset2{k});
end

%% Remove duplicates

for k = 1:num_slices-1
    cprintf('blue', 'Removing duplicates between "%s" and "%s"\n',...
        paths_to_dataset2{k}, paths_to_dataset2{k+1});
    remove_duplicates(ds2{k}, ds2{k+1});
end

for k = 1:num_slices
    save_name = ds2{k}.save_class;
    movefile(save_name, paths_to_dataset2{k});
end

%% Match 1P/2P

load('match_pre.mat', 'info');

for k = 1:num_slices
    close all;

    matched_corrlist = match_1p2p(ds1, ds2{k}, info.tform);
    cprintf('blue', 'Found %d matched cells between 1P and %s\n',...
        size(matched_corrlist,1), paths_to_dataset2{k});
    
    save('matched_corrlist.mat', 'matched_corrlist');
    movefile('matched_corrlist.mat', paths_to_dataset2{k});
end
