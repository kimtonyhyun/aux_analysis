function [traces, t_in_trial, frames_in_trial] = get_trial_traces(imdata, t_lims)
% Consider absorbing 'find_frames_in_trial'

[frames_in_trial, t_in_trial] = ctxstr.core.find_frames_in_trial(imdata.t, t_lims);
traces = imdata.traces(:,frames_in_trial);
