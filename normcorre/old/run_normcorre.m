function shifts = run_normcorre(movie_in, movie_out, varargin)
% Run NoRMCorre motion correction, with imaging data streamed from disk
%
% NormCorre obtained from https://github.com/simonsfoundation/NoRMCorre
%   on 2017 June 02 (latest commit f050cc1 / Apr 26).

% Default parameters
use_nonrigid = true;
grid_size = [128, 128];
max_shift = 50;

for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'rigid'
                use_nonrigid = false;
            case 'grid'
                grid_size = varargin{k+1}*[1 1];
        end
    end
end

[~, name, ext] = fileparts(movie_in);
if isempty(movie_out)
    if use_nonrigid
        movie_out = sprintf('%s_nc.hdf5', name);
    else
        movie_out = sprintf('%s_nc-rigid.hdf5', name);
    end
    fprintf('run_normcorre: Output movie will be saved as "%s"\n', movie_out);
end

switch lower(ext)
    case '.tif'
        info = imfinfo(movie_in);
        movie_size = [info.Height info.Width length(info)];
    case {'.hdf5', '.h5'}
        % FIXME: Hard-coded to save data to '/Data/Images'
        [movie_size, ~] = get_dataset_info(movie_in, '/Data/Images');
end

if use_nonrigid
    % Non-rigid settings
    fprintf('%s: Nonrigid NC grid size is [%d %d] px, with max shift of %d px\n',...
        movie_in, grid_size(1), grid_size(2), max_shift);
    options = NoRMCorreSetParms('d1',movie_size(1),'d2',movie_size(2),...
                        'grid_size',grid_size,...
                        'mot_uf',4,'bin_width',50,...
                        'max_shift',max_shift,'max_dev',3,'us_fac',50,...
                        'iter', 2,...
                        'output_type', 'hdf5',...
                        'h5_groupname', 'Data/Images',...
                        'h5_filename', movie_out);
else
    fprintf('run_normcorre: Using RIGID motion correction!\n');
    options = NoRMCorreSetParms('d1',movie_size(1),'d2',movie_size(2),...
                        'bin_width',50,...
                        'max_shift',max_shift, 'us_fac',50,...
                        'iter', 2,...
                        'output_type', 'hdf5',...
                        'h5_groupname', 'Data/Images',...
                        'h5_filename', movie_out);
end
tic;
[~, shifts] = normcorre_batch(movie_in, options);
t = toc;
fprintf('run_normcorre: Finished in %.1f minutes!\n', t/60);

% Save correction parameters to a separate file
info.movie_in = movie_in;
info.movie_out = movie_out;
info.nc_nonrigid = use_nonrigid;
info.nc_options = options;
info.nc_runtime = t;

[~, movie_out_name] = fileparts(movie_out);
save_name = sprintf('%s.mat', movie_out_name);
save(save_name, 'info', 'shifts', '-v7.3');
