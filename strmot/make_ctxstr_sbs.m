clear all; close all;

% Source filenames
str_source = 'oh06-0206-str_uc_nc.hdf5';
ctx_source = 'oh06-0206-ctx_uc_nc.hdf5';
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
beh_skip = sum(data.behavior.frame_times < data.str.frame_times(1));

beh_frames = find_nearest_frames(data.str.frame_times, 1:str_bin:str_bin*num_output_frames,...
    data.behavior.frame_times);

%% Extract Str sub-movie

num_str_frames_to_load = num_output_frames * str_bin;
M_str = load_movie_from_hdf5(str_source, [1 num_str_frames_to_load]);
save_movie_to_hdf5(M_str,'str_chunk.hdf5');
clear M_str;
bin_movie_in_time('str_chunk.hdf5', 'sbs-str.hdf5', str_bin);
delete('str_chunk.hdf5');

%% Extract Ctx sub-movie

num_ctx_frames_to_load = num_output_frames * ctx_bin;
M_ctx = load_movie_from_hdf5(ctx_source, [ctx_skip+1 ctx_skip+num_ctx_frames_to_load]);
save_movie_to_hdf5(M_ctx,'ctx_chunk.hdf5');
clear M_ctx;
bin_movie_in_time('ctx_chunk.hdf5', 'sbs-ctx.hdf5', ctx_bin);
delete('ctx_chunk.hdf5');

%% Extract Behavior sub-movie

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

%%
clear all;

M_ctx = load_movie('sbs-ctx.hdf5');
M_str = load_movie('sbs-str.hdf5');
M_beh = load_movie('sbs-beh.hdf5');
% M_beh = M_beh(1:1024,:,:); % Keep top
M_beh = M_beh(end-1023:end,:,:); % Keep bottom

%%

ctx_clim = [0 6];
M_ctx2 = uint8(255*(M_ctx-ctx_clim(1))/(ctx_clim(2)-ctx_clim(1)));

str_clim = [0 5];
M_str2 = uint8(255*(M_str-str_clim(1))/(str_clim(2)-str_clim(1)));

M = cat(1, M_ctx2, M_str2);
M = cat(2, M_beh, M);


