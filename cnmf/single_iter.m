function [A2, C2, b2, f2, P2] = single_iter(Yr, A, C, b, f, P, options)

tic;
[A2, b2, C2] = update_spatial_components(Yr, C, f, [A, b], P, options);
[C2, f2, P2] = update_temporal_components(Yr, A2, b2, C2, f, P, options);
t = toc;
fprintf('Finished CNMF iteration in %.1f minutes!\n', t/60);