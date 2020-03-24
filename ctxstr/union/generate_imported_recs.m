dataset_name = dirname;
dataset_date = dataset_name(end-3:end);

matches = dir(sprintf('match_%s_*.mat', dataset_date));