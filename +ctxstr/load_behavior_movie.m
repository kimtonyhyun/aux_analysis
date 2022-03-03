function Mb = load_behavior_movie(movie_filename, trials)
% Load behavioral video data associated with each trial. For typical CtxStr
% recordings (i.e. 122.5 Hz; converted to MP4 via Handbrake), 'Mb' is
% expected to occupy ~100 GB in memory.
vid = VideoReader(movie_filename);

num_trials = length(trials);
Mb = cell(num_trials, 1);

for k = 1:num_trials
    fprintf('%d/%d: ', k, num_trials);
    Mb{k} = load_behavior_movie_frames(vid,...
                trials(k).t_dlc(1,2), trials(k).t_dlc(end,2));
end