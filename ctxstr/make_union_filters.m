
dataset_name = dirname;
imported_datasets = dir('from_*');
num_imports = length(imported_datasets);
fprintf('%s: For "%s" found %d imported datasets\n',...
    datestr(now), dataset_name, num_imports);

%%

% Primary dataset
ds = DaySummary([], 'cnmf1/iter2');
imports = cell(num_imports, 2); % [Name(string) DaySummary]

for k = 1:num_imports
    import_name = imported_datasets(k).name;
    imports{k,1} = import_name;
    imports{k,2} = DaySummary([], import_name);
end
clear imported_datasets import_name k;

%%

load(sprintf('%s-ctx.mat', dataset_name)); % FIXME: Striatum?
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