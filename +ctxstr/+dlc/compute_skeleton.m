function compute_skeleton(dlc)

front_left = dlc.front_left(:,1:2);
front_right = dlc.front_right(:,1:2);

hind_left = dlc.hind_left(:,1:2);
hind_right = dlc.hind_right(:,1:2);

nose = dlc.nose(:,1:2);
tail = dlc.tail(:,1:2);

tn_vec = tail - nose; % Nose-to-tail vector
alpha_n = 180/pi*atan2(tn_vec(:,2), tn_vec(:,1));
ax1 = subplot(311);
tight_plot(dlc.t, alpha_n);
ylabel('Nose-tail angle, \alpha_n (degrees)');
set(ax1, 'TickLength', [0 0]);

frfl_vec = front_right - front_left;
alpha_f = 180/pi*atan2(frfl_vec(:,2), frfl_vec(:,1));

hrhl_vec = hind_right - hind_left;
alpha_h = 180/pi*atan2(hrhl_vec(:,2), hrhl_vec(:,1));

beta_f = alpha_f - alpha_n;
beta_h = alpha_h - alpha_n;

ax2 = subplot(312);
yyaxis left;
tight_plot(dlc.t, beta_f);
hold on;
plot(dlc.t([1 end]), 90*[1 1], 'k--');
hold off;
ylabel('Front limb angle, \beta_f (degrees)');
yyaxis right;
tight_plot(dlc.t, beta_h);
ylabel('Hind limb angle, \beta_h (degrees)');
set(ax2, 'TickLength', [0 0]);

linkaxes([ax1 ax2], 'x');