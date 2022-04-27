function [traces, t_in_trial, frames_in_trial] = get_traces_by_time(orig_traces, t, t_lims)

[frames_in_trial, t_in_trial] = ctxstr.core.find_frames_by_time(t, t_lims);
traces = orig_traces(:,frames_in_trial);
