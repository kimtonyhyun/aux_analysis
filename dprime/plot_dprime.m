clear;

DFF = 0.19; % GCaMP6f, Chen et al. 2013
tau = 0.142 / log(2); % GCaMP6f (s)

fovs = linspace(10, 500, 3e2); % Length of FOV edge
nus = [linspace(0.1, 10, 100) linspace(10, 200, 100)];

[N,F] = meshgrid(nus, fovs);

Ds = zeros(size(F));
Ds_approx = zeros(size(F));

F0 = 563.1091; % Photon/s when scanning over fov0
fov0_a = 20^2;

for i = 1:size(F,1)
    fov = fovs(i);
    fov_a = fov^2;
    for j = 1:size(N,2)
        nu = nus(j);
        [d, d_approx] = compute_dprime(F0 * fov0_a/fov_a, nu, DFF, tau);
        Ds(i,j) = d;
        Ds_approx(i,j) = d_approx;
    end
end

%% d-prime values for Svoboda mesoscope

[d, d_approx] = compute_dprime(F0 * fov0_a / (4*600*600), 9.5, DFF, tau);

%%

close all;

surf(N,F,log10(Ds));
view(2);
shading interp;
colorbar;
set(gca, 'Xscale', 'log');
xlabel('Frame rate');
ylabel('FOV (\mum)');
xlim(nus([1 end]));
ylim([0 fovs(end)]);
hold on;

%%

contour(N,F,log10(Ds),log10([0.125/2 0.125 0.25 0.5 1]),'k');
hold on;
view(2);
colorbar;
set(gca, 'Xscale', 'log');
xlabel('Frame rate');
ylabel('FOV (\mum)');
xlim(nus([1 end]));
ylim([0 fovs(end)]);

plot3(160, 20, 10, 'k.');
plot3(30, 400, 10, 'k.');
set(gcf, 'Renderer', 'painters');