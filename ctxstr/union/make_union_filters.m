clear all;

% Identify datasets
dataset_name = dirname;
imported_datasets = dir('from_*');
num_imports = length(imported_datasets);
fprintf('%s: For "%s" found %d imported datasets\n',...
    datestr(now), dataset_name, num_imports);

%% Load all data as DS

% Primary dataset
ds = DaySummary([], 'cnmf1/iter2'); % FIXME: Hard-coded
imports = cell(num_imports, 2); % [Name(string) DaySummary]

for k = 1:num_imports
    import_name = imported_datasets(k).name;
    imports{k,1} = import_name;
    imports{k,2} = DaySummary([], import_name);
end
clear imported_datasets import_name k;

%% Produce diagnostic plot

image_file = dir(sprintf('%s-*.mat', dataset_name)); % Be careful
load(image_file.name);
imagesc(A, [0.5 3]);
axis image; colormap gray;
hold on;
plot_boundaries_with_transform(ds, 'g', 2);

colors = flipud(hot(num_imports+2));
for k = 1:num_imports
    plot_boundaries_with_transform(imports{k,2}, colors(k,:), 1, [], [], true);
end
hold off;
title(sprintf('%s: Original (green) vs. Imported filters (other colors)\nDashed: Rejected during manual classification',...
    dataset_name));
set(gca, 'FontSize', 18);

%% Make merge MD

md = create_merge_md([{ds}; imports(:,2)]);

%% Resolve duplicates

res_list = resolve_recs(md, 'norm_traces');

%% Generate "resolved" rec file

save_resolved_recs(res_list, md);