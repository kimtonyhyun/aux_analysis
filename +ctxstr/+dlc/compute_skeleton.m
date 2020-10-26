function compute_skeleton(dlc_data)
% Compute skeleton parameters from raw DLC coordinates. See definitions in
% the 2020 Oct 20 diagram.

t = dlc_data.t;

front_left = dlc_data.front_left(:,1:2);
front_right = dlc_data.front_right(:,1:2);

hind_left = dlc_data.hind_left(:,1:2);
hind_right = dlc_data.hind_right(:,1:2);

nose = dlc_data.nose(:,1:2);
tail = dlc_data.tail(:,1:2);

% Convert coordinates to skeleton parameters
%------------------------------------------------------------

% Angles
body_vec = tail - nose; % Nose-to-tail vector
alpha_n = 180/pi*atan2(body_vec(:,2), body_vec(:,1));

front_limb_vec = front_right - front_left;
alpha_f = 180/pi*atan2(front_limb_vec(:,2), front_limb_vec(:,1));

hind_limb_vec = hind_right - hind_left;
alpha_h = 180/pi*atan2(hind_limb_vec(:,2), hind_limb_vec(:,1));

beta_f = alpha_f - alpha_n;
beta_h = alpha_h - alpha_n;

% Distances
body_dir = normr(body_vec);

front_vec = 1/2*(front_left + front_right) - nose;
hind_vec = 1/2*(hind_left + hind_right) - nose;

d_f = sum(front_vec .* body_dir,2);
d_h = sum(hind_vec .* body_dir,2);

save('skeleton', 't', 'alpha_n', 'beta_f', 'beta_h', 'd_f', 'd_h');

end % compute_skeleton
