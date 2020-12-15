function plot_coords(dlc)

t = dlc.t;

ax1 = subplot(6,2,1);
tight_plot(t, dlc.front_left(:,1));
ylabel('front left x');
ax2 = subplot(6,2,2);
tight_plot(t, dlc.front_left(:,2));
ylabel('front left y');

ax3 = subplot(6,2,3);
tight_plot(t, dlc.front_right(:,1));
ylabel('front right x');
ax4 = subplot(6,2,4);
tight_plot(t, dlc.front_right(:,2));
ylabel('front right y');

ax5 = subplot(6,2,5);
tight_plot(t, dlc.hind_left(:,1));
ylabel('hind left x');
ax6 = subplot(6,2,6);
tight_plot(t, dlc.hind_left(:,2));
ylabel('hind left y');

ax7 = subplot(6,2,7);
tight_plot(t, dlc.hind_right(:,1));
ylabel('hind right x');
ax8 = subplot(6,2,8);
tight_plot(t, dlc.hind_right(:,2));
ylabel('hind right y');

linkaxes([ax1 ax2 ax3 ax4 ax5 ax6 ax7 ax8], 'x');

subplot(6,2,9);
tight_plot(t, dlc.nose(:,1));
ylabel('nose x');
subplot(6,2,10);
tight_plot(t, dlc.nose(:,2));
ylabel('nose y');

subplot(6,2,11);
tight_plot(t, dlc.tail(:,1));
ylabel('tail x');
subplot(6,2,12);
tight_plot(t, dlc.tail(:,1));
ylabel('tail y');