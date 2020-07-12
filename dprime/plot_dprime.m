clear;

DFF = 0.19; % GCaMP6f, Chen et al. 2013
tau = 0.142 / log(2); % GCaMP6f (s)

fovs = 10:5:500; % Length of FOV edge (um)
nus = logspace(-1, log10(200), 100); % Frame rates (fps)

[N,F] = meshgrid(nus, fovs);

Ds = zeros(size(F));
Ds_approx = zeros(size(F));

F0 = 823.7469; % Photon/s when scanning over fov0, see below
fov0_a = 20^2; % um^2

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

FPR = 0.05; % False positive rate (5% in Huang et al.)
z0 = icdf('Normal', 1-FPR, 0, 1);
compute_tpr = @(x) 1-normcdf(z0-x);
TPRs = compute_tpr(Ds);
TPRs_approx = compute_tpr(Ds_approx);

%% Plot d-prime values

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

contour(N,F,log10(Ds),log10([0.125/2 0.125 0.25 0.5 1.0]),'k');
hold on;
contour(N,F,log10(Ds),log10([0.0846 1.7]),'k--');
view(2);
colorbar;
set(gca, 'Xscale', 'log');
xlabel('Frame rate');
ylabel('FOV (\mum)');
xlim(nus([1 end]));
ylim([0 fovs(end)]);

% Empirical operating points
plot3(158, 20, 100, 'k.');
plot3(30, 400, 100, 'k.');
set(gcf, 'Renderer', 'painters');