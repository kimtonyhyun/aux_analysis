function [Mb, tb] = load_behavior_movie(vid, t_vid, t_lims)
% Loads a subset of the behavioral video frames. Inputs:
%   - vid: VideoReader object
%   - t_vid: Frame times for behavioral video (i.e. behavior.frame_times)
%   - t_lims: Range of time from which to pull frames
% Outputs:
%   - Mb: Behavioral video (uint8)
%   - tb: Frame times corresponding to frames in Mb
%

% First, determine the range of frames to be loaded
ind1 = find(t_vid >= t_lims(1), 1, 'first');
ind2 = find(t_vid <= t_lims(2), 1, 'last');

tb = t_vid(ind1:ind2);
num_frames = length(tb);

tic;
fprintf('%s: Loading %d frames from "%s"... ',...
    datestr(now), num_frames, vid.Name);
Mb = vid.read([ind1 ind2]);
Mb = squeeze(Mb(:,:,1,:));
t = toc;
fprintf('Done! (%.1f s; %.1f ms per frame)\n', t, t/num_frames*1e3);