function f = compute_local_dff(dff_windows, to, f_tr)

% Unpack
t_pre = dff_windows(1);
t_spike = dff_windows(2);
t_post = dff_windows(3);

f.pre = interp1(to, f_tr, t_pre:t_spike, 'linear');
f.post = interp1(to, f_tr, t_spike:t_post, 'linear');

f.f0 = mean(f.pre);
f.peak = max(f.post);
f.dff = (f.peak - f.f0)/f.f0;
