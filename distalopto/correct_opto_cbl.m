%%
load('opto.mat');

A_off = compute_mean_image(M, laser_off);

num_levels = length(laser_on);
A_on = zeros(512, 512, num_levels);
for k = 1:num_levels
    A_on(:,:,k) = compute_mean_image(M, laser_on{k});
end

%%

D = zeros(512, 512, num_levels);
for k = 1:num_levels
    D(:,:,k) = A_on(:,:,k) - A_off;
end

save('diffmap', 'A_off', 'A_on', 'D');

%%

for k = 1:num_levels
    subplot(1,num_levels,k);
    imagesc(D(:,:,k), [-0.5 0.5]);
    axis image;
    colormap redblue;
    d = D(:,:,k);
    d = mean(d(:));
    title(sprintf('AVG laser on - AVG laser off: \\mu=%.4f', d));
end

%%

for k = 1:num_levels
    laser_on_k = laser_on{k};
    for m = laser_on_k
        M(:,:,m) = M(:,:,m) - D(:,:,k); %#ok<*SAGROW>
    end
end
fprintf('%s: Applied opto correction!\n', datestr(now));

%%
[S,A] = compute_std_image(M);

for k = 1:size(M,3)
    M(:,:,k) = (M(:,:,k)-A)./S;
end

fprintf('%s: Z-scored movie!\n', datestr(now));