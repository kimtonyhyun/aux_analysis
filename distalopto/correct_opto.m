%%
load('opto.mat');

A_off = compute_mean_image(M,laser_inds.off);
A_real = compute_mean_image(M,laser_inds.real);
A_sham = compute_mean_image(M,laser_inds.sham);

%%

D_real = A_real - A_off;
D_sham = A_sham - A_off;

d_real = mean(D_real(:));
d_sham = mean(D_sham(:));

% save('diffmap', 'A_off', 'A_real', 'A_sham', 'D_real', 'D_sham');

%%

subplot(121);
imagesc(D_real, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real opto - AVG laser off: \\mu=%.4f', d_real));

subplot(122);
imagesc(D_sham, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG sham opto - AVG laser off: \\mu=%.4f', d_sham));

%%

for k = laser_inds.real
    M(:,:,k) = M(:,:,k) - d_real;
end
for k = laser_inds.sham
    M(:,:,k) = M(:,:,k) - d_sham;
end
fprintf('%s: Applied opto correction!\n', datestr(now));

%%
[S,A] = compute_std_image(M);

for k = 1:size(M,3)
    M(:,:,k) = (M(:,:,k)-A)./S;
end

fprintf('%s: Z-scored movie!\n', datestr(now));