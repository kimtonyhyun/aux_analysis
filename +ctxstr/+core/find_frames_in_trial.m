function frames_in_trial = find_frames_in_trial(t, t_trial)

frames_in_trial = find((t > t_trial(1)) & (t < t_trial(2)));

end