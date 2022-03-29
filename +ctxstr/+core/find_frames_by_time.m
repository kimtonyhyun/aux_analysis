function [frames_in_trial, t_in_trial] = find_frames_by_time(t, t_lims)

frames_in_trial = find((t >= t_lims(1)) & (t <= t_lims(2)))'; % Row vector
t_in_trial = t(frames_in_trial);

end