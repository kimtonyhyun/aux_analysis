clear all;

% Expect subdirectories in the format 'slX' or 'slX_dY' where X is the
% slicing index and Y is the depth of the recording
datasets = dir('sl*');
num_datasets = length(datasets);

% From each slice, load DaySummary, mean projection image, and depth info
ds = cell(num_datasets, 1);
As = cell(num_datasets, 1); 

for k = 1:num_datasets
    % Load DaySummary
    path_to_rec = fullfile(datasets(k).name, 'ext1/ls');
    ds{k} = DaySummary([], path_to_rec);
    
    % Compute mean projection image
    movie_filename = dir(fullfile(datasets(k).name, '*_nc.hdf5'));
    movie_filename = fullfile(datasets(k).name, movie_filename.name);
    As{k} = compute_mean_image(movie_filename);
end

%% (Optional) Assign slices to depths, using the subdirectory name.

datasets = dir('sl*');
num_datasets = length(datasets);

depths_loaded = false;
depths = 1:num_datasets; % To be overwritten if depth info available
for k = 1:num_datasets
    S = sscanf(datasets(k).name, 'sl%d_d%d');
    if (length(S) > 1)
       depths_loaded = true;
       depths(k) = S(2); 
    end
end

%% Show 2P cell maps, and cell overlap in adjacent planes

colors = flipud(jet(num_datasets));

if depths_loaded
    [~, display_order] = sort(depths, 'ascend');
else
    display_order = 1:num_datasets;
end

sp = @(m,n,p) subtightplot(m, n, p, 0.01, 0.005, 0.01);
for k = 1:num_datasets
    sp(2,num_datasets,k);
    
    idx = display_order(k);
    imagesc(As{idx}, [0.5 3.5]);
    colormap gray;
    hold on;
    plot_boundaries(ds{idx}, 'Color', colors(k,:));
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
    if depths_loaded
        title(sprintf('sl%d - %d um (%d cells)', idx, depths(idx), ds{idx}.num_classified_cells));
    else
        title(sprintf('sl%d (%d cells)', idx, ds{idx}.num_classified_cells));
    end
end

sp = @(m,n,p) subtightplot(m, n, p, 0.01, 0.005, 0.09);

for k = 1:num_datasets-1
    sp(2,num_datasets-1,(num_datasets-1)+k);
    
    idx1 = display_order(k);
    idx2 = display_order(k+1);
    plot_boundaries(ds{idx1}, 'Color', colors(k,:), 'Width', 1);
    hold on;
    plot_boundaries(ds{idx2}, 'Color', colors(k+1,:));
    title(sprintf('sl%d vs. sl%d', idx1, idx2));
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
    set(gca, 'Color', 'k');
end

%% Load 1P-2P matched lists

datasets = dir('sl*');
num_datasets = length(datasets);

matches = cell(num_datasets, 1);
for k = 1:num_datasets
    path_to_mat = fullfile(datasets(k).name, 'matched_corrlist.mat');
    m = load(path_to_mat);
    matches{k} = m.matched_corrlist;
end
clear m;

%% Show 2P cell maps, identifying neurons that matched to 1P.

ds_1p = DaySummary('', '../1P/ext1/ls_ti6');

colors = flipud(jet(num_datasets));

if depths_loaded
    [~, display_order] = sort(depths, 'ascend');
else
    display_order = 1:num_datasets;
end

sp = @(m,n,p) subtightplot(m, n, p, 0.01, 0.005, [0.02 0.01]);
for k = 1:num_datasets
    sp(2,num_datasets,k);
    
    idx = display_order(k);
    imagesc(As{idx}, [0.5 3.5]);
    colormap gray;
    if k == 1
       ylabel('2P'); 
    end
    hold on;
    plot_boundaries(ds{idx}, 'Color', colors(k,:), 'filled_cells', matches{idx}(:,2));
    num_cells = ds{idx}.num_classified_cells;
    num_matched_cells = size(matches{idx}, 1);
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
    if depths_loaded
        title(sprintf('sl%d - %d um\n%d cells total\n%d cells matched to 1P (%.1f%%)',...
            idx, depths(idx),...
            num_cells,...
            num_matched_cells, 100*num_matched_cells/num_cells));
    else
        title(sprintf('sl%d (%d cells)', idx, ds{idx}.num_classified_cells));
    end
    
    sp(2,num_datasets,num_datasets+k);
    plot_boundaries(ds_1p, 'Color', colors(k,:), 'filled_cells', matches{idx}(:,1));
    if k == 1
        ylabel('1P');
    end
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
end