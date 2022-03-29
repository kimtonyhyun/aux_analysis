function [traces, t_in_trial, frames_in_trial] = get_traces_by_time(imdata, t_lims)

[frames_in_trial, t_in_trial] = ctxstr.core.find_frames_by_time(imdata.t, t_lims);
traces = imdata.traces(:,frames_in_trial);
