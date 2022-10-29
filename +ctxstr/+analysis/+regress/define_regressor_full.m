function r = define_regressor_full(name, trace, pre_dofs, post_dofs, t, trials)
% The regressor kernel ranges pre_samples:post_samples, where each temporal
% sample is an independently optimized parameter in the fit.

r.name = name;
r.type = 'full rank';
r.pre_dofs = pre_dofs;
r.post_dofs = post_dofs;
r.num_dofs = pre_dofs + 1 + post_dofs;

T = t(2) - t(1); % Deduce frame rate from provided time

r.j_kernel = (-pre_dofs:post_dofs);
r.t_kernel = T*r.j_kernel;
fprintf('%s kernel (full rank) has support over t = %.2f to %.2f s\n',...
    name, r.t_kernel(1), r.t_kernel(end));

r.basis_vectors = eye(r.num_dofs); % For common syntax with define_regressor_smooth

% trace = trace - mean(trace);
X = ctxstr.analysis.regress.generate_temporally_offset_regressors(trace, pre_dofs, post_dofs);
r.X_by_trial = ctxstr.core.parse_into_trials(X, t, trials);