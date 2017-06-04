function run_normcorre(movie_in, movie_out)
% Run NoRMCorre motion correction, with imaging data streamed from disk
% TODO: Allow for TIF input

if isempty(movie_out)
    [~, name] = fileparts(movie_in);
    movie_out = sprintf('%s_nc.hdf5', name);
    fprintf('run_normcorre: Output movie will be saved as "%s"\n', movie_out);
end

% FIXME: Hard-coded NoRMCorre code to save data to '/Data/Images'
[movie_size, ~] = get_dataset_info(movie_in, '/Data/Images');
options_nonrigid = NoRMCorreSetParms('d1',movie_size(1),'d2',movie_size(2),...
                    'grid_size',[64,64],...
                    'mot_uf',4,'bin_width',50,...
                    'max_shift',50,'max_dev',3,'us_fac',50,...
                    'output_type', 'hdf5',...
                    'h5_groupname', 'Data/Images',...
                    'h5_filename', movie_out);
tic;
normcorre_batch(movie_in, options_nonrigid);
t = toc;
fprintf('run_normcorre: Finished in %.1f minutes!\n', t/60);