function plot_opto_diffmap(M, laser_off, laser_on, varargin)

use_boundary = 0;
for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'boundary'
                use_boundary = 1;
                ds = varargin{k+1};
        end
    end
end

% Compute
F = compute_fluorescence_stats(M);
mu = F(:,2);

A_on = mean(M(:,:,laser_on),3);
A_off = mean(M(:,:,laser_off),3);
D = A_on - A_off;

% Display
subplot(3,1,1);
plot_opto_trace(mu, laser_off, laser_on);
xlabel('Frames');
ylabel('Norm fluorescence');

subplot(3,1,[2 3]);
imagesc(D,[-0.5 0.5]);
title('AVG laser ON - AVG laser OFF');
hold on;
axis image;
colormap redblue;
colorbar;

% Show boundary
if (use_boundary)
    plot_boundaries_with_transform(ds, 'k', 1, [], []);
    title(sprintf('AVG laser ON - AVG laser OFF: %d classified cells', ds.num_classified_cells));
end
subplot(3,1,1); % For manual title