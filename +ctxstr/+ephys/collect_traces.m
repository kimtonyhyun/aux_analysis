clear;

cell_name = dirname; % e.g. "cell_03"
files = dir(sprintf('%s_*.tif', cell_name));
num_files = length(files);
fprintf('Found %d movies\n', num_files);

%%

load('filter.mat');

im_filenames = cell(1, num_files);
dff_traces = cell(1, num_files);

ephys_filenames = cell(1, num_files);
ephys_traces = cell(1, num_files);
spike_samples = cell(1, num_files);

for j = 1:num_files
    im_filenames{j} = files(j).name;
    
    % Find the corresponding ephys file by matching the recording index
    idx = sscanf(im_filenames{j}, sprintf('%s_%%03d.tif', cell_name));
    ephys_filenames{j} = sprintf('AD0_%d.mat', idx);
    
    fprintf('%s: Working on "%s"/"%s"...\n',...
        datestr(now), im_filenames{j}, ephys_filenames{j});
    
    % Load imaging data and compute DFF trace
    M = load_scanimage_tif(im_filenames{j});
    M = double(M);
    num_frames = size(M,3);
    
    trace = zeros(num_frames, 1);
    for k = 1:num_frames
        DP = M(:,:,k).*filter; % Dot product
        trace(k) = sum(DP(:));
    end
    
    F0 = mean(trace(1:128)); % First 128 samples corresponds to 8 s at 16 Hz. Spike comes on at t = 10 s.
    dff_traces{j} = (trace - F0)/F0;
    
    % Load matched ephys data
    edata = load(ephys_filenames{j});
    ephys_traces{j} = edata.(sprintf('AD0_%d', idx)).data;
    
    spike_file = sprintf('spikes_%03d.mat', idx);
    if isfile(spike_file)
        sdata = load(spike_file);
        spike_samples{j} = sdata.spike_samples;
    end
end

%%

inds_to_save = 38:81;

clear info;
info.type = 'Ephys/2P';
info.num_pairs = length(inds_to_save);
info.fps = 15.625;
info.im_filenames = im_filenames(inds_to_save);
info.ephys_filenames = ephys_filenames(inds_to_save);
info.ephys_traces = ephys_traces(inds_to_save);
info.spike_samples = spike_samples(inds_to_save);

traces = cell2mat(dff_traces(inds_to_save));
filters = repmat(filter, 1, 1, info.num_pairs);

rec_filename = save_rec(info, filters, traces);

rec_dirname = sprintf('%d-%d', inds_to_save(1), inds_to_save(end));
mkdir(rec_dirname);
movefile(rec_filename, rec_dirname);