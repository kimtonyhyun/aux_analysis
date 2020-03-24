function check_dlc(dlc_coords)

num_frames = size(dlc_coords,1);

ax1 = subplot(311);
plot(dlc_coords(:,1),'.-');
ylabel('x');
xlim([1 num_frames]);

ax2 = subplot(312);
plot(dlc_coords(:,2),'.-');
ylabel('y');
xlim([1 num_frames]);

ax3 = subplot(313);
plot(dlc_coords(:,3),'.-');
ylabel('conf');
xlim([1 num_frames]);

linkaxes([ax1 ax2 ax3], 'x');