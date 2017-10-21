function run_normcorre_batch(file_list)

N_files = length(file_list);
fprintf('Received %d files to process...\n', N_files);
for k = 1:N_files
    filename = file_list{k};
    dataset_size = get_dataset_info('m753-1020-sl1.hdf5', '/Data/Images');
    fprintf('  File "%s" has %d frames...\n', filename, dataset_size(3));
end

fprintf('Running NoRMCorre...\n');
for k = 1:N_files
    filename = file_list{k};
    run_normcorre(filename, '');
end