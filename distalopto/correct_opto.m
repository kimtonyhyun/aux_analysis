%% Use for STANDARD opto sessions

load('opto.mat');

A_off = compute_mean_image(M,laser_inds.off);
A_real = compute_mean_image(M,laser_inds.real);
A_sham = compute_mean_image(M,laser_inds.sham);

D_real = A_real - A_off;
D_sham = A_sham - A_off;

d_real = mean(D_real(:));
d_sham = mean(D_sham(:));

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

%% Use for POWER MOD opto sessions

load('opto.mat');

A_off = compute_mean_image(M,laser_inds.off);
A_real_low = compute_mean_image(M,laser_inds.real_low);
A_real_mid = compute_mean_image(M,laser_inds.real_mid);
A_real_high = compute_mean_image(M,laser_inds.real_high);

D_low = A_real_low - A_off;
D_mid = A_real_mid - A_off;
D_high = A_real_high - A_off;

d_low = mean(D_low(:));
d_mid = mean(D_mid(:));
d_high = mean(D_high(:));

subplot(131);
imagesc(D_low, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real low - AVG laser off: \\mu=%.4f', d_low));

subplot(132);
imagesc(D_mid, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real mid - AVG laser off: \\mu=%.4f', d_mid));

subplot(133);
imagesc(D_high, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real high - AVG laser off: \\mu=%.4f', d_high));

%%

for k = laser_inds.real_low
    M(:,:,k) = M(:,:,k) - d_low;
end
for k = laser_inds.real_mid
    M(:,:,k) = M(:,:,k) - d_mid;
end
for k = laser_inds.real_high
    M(:,:,k) = M(:,:,k) - d_high;
end
fprintf('%s: Applied opto correction (POWER MOD)!\n', datestr(now));

%% Use for TEMPORAL MOD opto sessions

load('opto.mat');

A_off = compute_mean_image(M,laser_inds.off);
A_real_postline = compute_mean_image(M,laser_inds.real_postline);
A_real_interlace = compute_mean_image(M,laser_inds.real_interlace);
A_real_alternate = compute_mean_image(M,laser_inds.real_alternate);

D_postline = A_real_postline - A_off;
D_interlace = A_real_interlace - A_off;
D_alternate = A_real_alternate - A_off;

d_postline = mean(D_postline(:));
d_interlace = mean(D_interlace(:));
d_alternate = mean(D_alternate(:));

subplot(131);
imagesc(D_postline, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real postline - AVG laser off: \\mu=%.4f', d_postline));

subplot(132);
imagesc(D_interlace, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real interlace - AVG laser off: \\mu=%.4f', d_interlace));

subplot(133);
imagesc(D_alternate, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real alternate - AVG laser off: \\mu=%.4f', d_alternate));

%%

for k = laser_inds.real_postline
    M(:,:,k) = M(:,:,k) - d_postline;
end
for k = laser_inds.real_interlace
    M(:,:,k) = M(:,:,k) - d_interlace;
end
for k = laser_inds.real_alternate
    M(:,:,k) = M(:,:,k) - d_alternate;
end
fprintf('%s: Applied opto correction (TEMPORAL MOD)!\n', datestr(now));


%% Z-score movie

[S,A] = compute_std_image(M);

for k = 1:size(M,3)
    M(:,:,k) = (M(:,:,k)-A)./S;
end

fprintf('%s: Z-scored movie!\n', datestr(now));