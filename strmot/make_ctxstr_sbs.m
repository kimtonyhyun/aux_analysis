clear all; close all;

% Source filenames
stem = dirname; % e.g. "oh09-0204"
str_source = sprintf('%s-str_uc_nc.hdf5', stem);
ctx_source = sprintf('%s-ctx_uc_nc.hdf5', stem);
beh_source = 'test.mp4';

% Output (side-by-side) video parameters
fps = 30;
sbs_duration = 20; % sec

ctx_bin = 8;
str_bin = 45/30*ctx_bin; % Ratio of acquisition frame rates

num_output_frames = fps * sbs_duration;

%% Timing

data = load('ctxstr.mat'); % Output of 'parse_ctxstr.m'

% Str recording is always the last to start
ctx_skip = sum(data.ctx.frame_times < data.str.frame_times(1));

beh_frames = find_nearest_frames(data.str.frame_times, 1:str_bin:str_bin*num_output_frames,...
    data.behavior.frame_times);

%% Generate Str sub-movie (sbs-str.hdf5)

num_str_frames_to_load = num_output_frames * str_bin;
M_str = load_movie_from_hdf5(str_source, [1 num_str_frames_to_load]);
save_movie_to_hdf5(M_str,'str_chunk.hdf5');
clear M_str;
bin_movie_in_time('str_chunk.hdf5', 'sbs-str.hdf5', str_bin);
delete('str_chunk.hdf5');

%% Generate Ctx sub-movie (sbs-ctx.hdf5)

num_ctx_frames_to_load = num_output_frames * ctx_bin;
M_ctx = load_movie_from_hdf5(ctx_source, [ctx_skip+1 ctx_skip+num_ctx_frames_to_load]);
save_movie_to_hdf5(M_ctx,'ctx_chunk.hdf5');
clear M_ctx;
bin_movie_in_time('ctx_chunk.hdf5', 'sbs-ctx.hdf5', ctx_bin);
delete('ctx_chunk.hdf5');

%% Generate Behavior sub-movie (sbs-beh.hdf5)

vid = VideoReader(beh_source);

M = zeros(1080, 810, num_output_frames, 'uint8');
m = 1; % output frame

k = 0;
while (k < beh_frames(end))
    k = k + 1; % current input frame index
    A = vid.readFrame;
    if (k == beh_frames(m))
        fprintf('%s: Reading frame %d (%d of %d)\n',...
            datestr(now), k, m, num_output_frames);
        
%         % Following conversion due to Handbrake encoding
%         A = A(:);
%         A = reshape(A, [1080 1080, 4]);
        
        M(:,:,m) = A(:,:,1);
        m = m + 1;
    end
end
save_movie_to_hdf5(M, 'sbs-beh.hdf5');
clear M;

%% Load all sub-movies
clear all;

M_ctx = load_movie('sbs-ctx.hdf5');
M_str = load_movie('sbs-str.hdf5');
M_beh = load_movie('sbs-beh.hdf5');
% M_beh = M_beh(1:1024,:,:); % Keep top
M_beh = M_beh(end-1023:end,:,:); % Keep bottom

%% Scale neural data to uint8 scale

ctx_clim = [0 5];
M_ctx2 = uint8(255*(M_ctx-ctx_clim(1))/(ctx_clim(2)-ctx_clim(1)));

str_clim = [0 5];
M_str2 = uint8(255*(M_str-str_clim(1))/(str_clim(2)-str_clim(1)));

%% Generate GRAYSCALE side-by-side movie M

M = cat(1, M_ctx2, M_str2);
M = cat(2, M_beh, M);

clear M_ctx2 M_str2;

%% Generate RGB movies

% Retrieve tdTomato overlays
stem = dirname;
str_tdt_source = sprintf('%s-str-tdt.mat', stem);
str_tdt = load(str_tdt_source);
ctx_tdt_source = sprintf('%s-ctx-tdt.mat', stem);
ctx_tdt = load(ctx_tdt_source);

str_tdt_clim = [0 4.5];
str_tdt.A2 = uint8(255*(str_tdt.A-str_tdt_clim(1))/...
    (str_tdt_clim(2)-str_tdt_clim(1)));

ctx_tdt_clim = [0 4];
ctx_tdt.A2 = uint8(255*(ctx_tdt.A-ctx_tdt_clim(1))/...
    (ctx_tdt_clim(2)-ctx_tdt_clim(1)));

num_frames = size(M_str2,3);
M_str3 = zeros(512, 512, 3, num_frames, 'uint8');
M_ctx3 = zeros(512, 512, 3, num_frames, 'uint8');
for k = 1:num_frames
    M_str3(:,:,1,k) = str_tdt.A2; % red
    M_str3(:,:,2,k) = M_str2(:,:,k); % green
    
    M_ctx3(:,:,1,k) = ctx_tdt.A2;
    M_ctx3(:,:,2,k) = M_ctx2(:,:,k);
end

% Convert behavior video to RGB
[h, w, num_frames] = size(M_beh);
M_beh3 = zeros(h, w, 3, num_frames, 'uint8');
for k = 1:num_frames
    M_beh3(:,:,1,k) = M_beh(:,:,k);
    M_beh3(:,:,2,k) = M_beh(:,:,k);
    M_beh3(:,:,3,k) = M_beh(:,:,k);
end

%% Generate RGB side-by-side movie M

M = cat(1, M_ctx3, M_str3);
M = cat(2, M_beh3, M);
