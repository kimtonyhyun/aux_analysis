%% Evaluate post-merge 1P/2P filters

clear all;

path_to_dataset1 = '1P/merge/ls_ti6';
paths_to_dataset2 = {'2P/sl2_d150/ext1/ls';
                     '2P/sl3_d200/ext1/ls';
                     '2P/sl4_d250/ext1/ls';
                     '2P/sl5_d300/merge/ls';
                     '2P/sl6_d350/ext1/ls';
                     '2P/sl1_d400/ext1/ls';
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

%% Show 1P:2P cell maps, filling in cells that matched

% Load all matched_corrlists
matches = cell(num_slices, 1);
for k = 1:num_slices
    path_to_mat = fullfile(paths_to_dataset2{k}, 'matched_corrlist.mat');
    m = load(path_to_mat);
    matches{k} = m.matched_corrlist;
end
clear path_to_mat m;

% Load mean projection images
As = cell(num_slices, 1);
for k = 1:num_slices
    path_to_movie = fullfile(paths_to_dataset2{k},'..','..');
    movie_filename = dir(fullfile(path_to_movie, '*_nc.hdf5'));
    movie_filename = fullfile(path_to_movie, movie_filename.name);
    As{k} = compute_mean_image(movie_filename);
end
clear path_to_movie movie_filename;

colors = flipud(jet(num_slices));

sp = @(m,n,p) subtightplot(m, n, p, 0.01, 0.005, [0.02 0.01]);
for k = 1:num_slices
    sp(2,num_slices,k);
    
    imagesc(As{k}, [0.5 3.5]);
    colormap gray;
    axis image;
    if k == 1
       ylabel('2P'); 
    end
    hold on;
    plot_boundaries(ds2{k}, 'Color', colors(k,:), 'filled_cells', matches{k}(:,2));
    num_cells = ds2{k}.num_classified_cells;
    num_matched_cells = size(matches{k}, 1);
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
    
    title(sprintf('%s\n%d cells total\n%d cells matched to 1P (%.1f%%)',...
        paths_to_dataset2{k},...
        num_cells,...
        num_matched_cells, 100*num_matched_cells/num_cells),...
        'Interpreter', 'None');
    
    sp(2,num_slices,num_slices+k);
    plot_boundaries(ds1, 'Color', colors(k,:), 'filled_cells', matches{k}(:,1));
    if k == 1
        ylabel('1P');
    end
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
end