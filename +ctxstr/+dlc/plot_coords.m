function plot_coords(dlc)

t = dlc.t;

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

ax1 = sp(6,2,1);
tight_plot(t, dlc.front_left(:,1));
ylabel('front left x');
ax2 = sp(6,2,2);
tight_plot(t, dlc.front_left(:,2));
ylabel('front left y');

ax3 = sp(6,2,3);
tight_plot(t, dlc.front_right(:,1));
ylabel('front right x');
ax4 = sp(6,2,4);
tight_plot(t, dlc.front_right(:,2));
ylabel('front right y');

ax5 = sp(6,2,5);
tight_plot(t, dlc.hind_left(:,1));
ylabel('hind left x');
ax6 = sp(6,2,6);
tight_plot(t, dlc.hind_left(:,2));
ylabel('hind left y');

ax7 = sp(6,2,7);
tight_plot(t, dlc.hind_right(:,1));
ylabel('hind right x');
ax8 = sp(6,2,8);
tight_plot(t, dlc.hind_right(:,2));
ylabel('hind right y');

linkaxes([ax1 ax2 ax3 ax4 ax5 ax6 ax7 ax8], 'x');

sp(6,2,9);
tight_plot(t, dlc.nose(:,1));
ylabel('nose x');
sp(6,2,10);
tight_plot(t, dlc.nose(:,2));
ylabel('nose y');

sp(6,2,11);
tight_plot(t, dlc.tail(:,1));
ylabel('tail x');
sp(6,2,12);
tight_plot(t, dlc.tail(:,1));
ylabel('tail y');