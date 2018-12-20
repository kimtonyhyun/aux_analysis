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

%% Fix the interlace artifact

% These are the lines _following_ block transition
transition_lines = [104 207 310 413];
num_lines = 70; % Lines to consider _after_ each transition

% First, find the average profile for the transient brightness increase
% following block transitions
D_interlace_y = mean(D_interlace,2); % Project out fast-axis
subplot(121);
plot(D_interlace_y,'.');
num_transitions = length(transition_lines);

D_interlace_y_mean = zeros(num_lines,1);
for k = 1:num_transitions
    tl = transition_lines(k);
    D_interlace_y_mean = D_interlace_y_mean + ...
        D_interlace_y(tl:tl+num_lines-1);
end
D_interlace_y_mean = D_interlace_y_mean / num_transitions;
subplot(122);
plot(D_interlace_y_mean,'.');

% Next, regenerate the diff image based on the fitted increase
% TODO: Actually _fit_ the exponential profile
D_interlace2_y = zeros(512, 1);
for k = 1:num_transitions
    tl = transition_lines(k);
    D_interlace2_y(tl:tl+num_lines-1) = D_interlace_y_mean;
end

D_interlace2 = kron(D_interlace2_y, ones(1,512));

%%

% Exclude PMT artifacts at edges
D_postline2 = D_postline(:,8:505);

d_postline = mean(D_postline2(:));
d_interlace = mean(D_interlace(:));
d_alternate = mean(D_alternate(:));

subplot(2,3,[1 4]);
imagesc(D_postline, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real postline - AVG laser off: \\mu=%.4f', d_postline));

subplot(2,3,2);
imagesc(D_interlace, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real interlace - AVG laser off: \\mu=%.4f', d_interlace));

subplot(2,3,5);
D_interlace_corrected = D_interlace - D_interlace2;
imagesc(D_interlace_corrected, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('Interlace corrected: \\mu=%.4f', mean(D_interlace_corrected(:))));

subplot(2,3,[3 6]);
imagesc(D_alternate, [-0.5 0.5]);
axis image;
colormap redblue;
colorbar;
title(sprintf('AVG real alternate - AVG laser off: \\mu=%.4f', d_alternate));

%%

for k = laser_inds.real_postline
    M(:,:,k) = M(:,:,k) - d_postline;
end
% Note that the interlace fix is _not_ full field!
for k = laser_inds.real_interlace
    M(:,:,k) = M(:,:,k) - D_interlace2;
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