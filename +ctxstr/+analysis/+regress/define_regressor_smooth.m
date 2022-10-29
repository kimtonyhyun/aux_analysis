function r = define_regressor_smooth(name, trace, pre_dofs, post_dofs, spacing, t, trials)
% The regressor kernel is approximated by raised cosines of width W = 4*S,
% where S is the 'spacing'. We allow for 'pre_dofs' number of raised
% cosines before t=0, i.e. centered at 
%   t = -pre_dofs*spacing, ..., -2*spacing, -1*spacing
% and likewise for 'post_dofs' number of raised cosines after t = 0, i.e.
% centered at
%   t = 1*spacing, 2*spacing, ..., post_dofs*spacing
%
% Compared to a full rank parameterization of the kernel over the same
% range of temporal samples spanned by the raised cosines, the smooth basis
% reduces the total degrees-of-freedom by approximately factor 1/spacing.

% TODO: Use an object, rather than struct, to represent a regressor?

r.name = name;
r.type = sprintf('raised cosines, spacing=%d samples', spacing);
r.pre_dofs = pre_dofs;
r.post_dofs = post_dofs;
r.num_dofs = pre_dofs + 1 + post_dofs;

T = t(2) - t(1); % Deduce frame rate from provided time

% The full range of time samples where the kernel has nonzero support. The
% factor 2*spacing comes from the fact that the raised cosine centered at 0
% has width = 4*spacing.
% NOTE: Technically t([1 end]) == [0 0], so the endpoints do not have
% non-zero support
j = -(2+pre_dofs)*spacing:(2+post_dofs)*spacing;

r.j_kernel = j;
r.t_kernel = T*j; % Time axis in seconds
fprintf('%s kernel (smoothed basis) has support over t = %.2f to %.2f s\n',...
    name, r.t_kernel(1), r.t_kernel(end));

centers = spacing*(-pre_dofs:post_dofs);

% Generate basis vectors. Note: Can use
%   plot(r.t_kernel, r.basis_vectors');
% to visualize the individual raised cosines.
r.basis_vectors = zeros(r.num_dofs, length(j));
for k = 1:r.num_dofs
    r.basis_vectors(k,:) = raised_cosine(j, centers(k), 4*spacing);
end

% Generate the design matrix, first as if for a full rank parameterization
% of the kernel over 'j' (defined above). Then, reduce the full rank
% parameterization using the basis vectors.
X = ctxstr.analysis.regress.generate_temporally_offset_regressors(trace, -j(1), j(end));
X = r.basis_vectors*X;
r.X_by_trial = ctxstr.core.parse_into_trials(X, t, trials);

end

function y = raised_cosine(x, center, width)
    mask = double(abs(x-center) <= width/2);
    y = 1/2*(cos(2*pi*(x-center)/width) + 1);
    y = mask .* y;
end