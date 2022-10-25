function r = define_regressor_full(name, trace, pre_samples, post_samples, t, trials)
% The regressor kernel ranges pre_samples:post_samples, where each temporal
% sample is an independently optimized parameter in the fit.

r.name = name;
r.pre_samples = pre_samples;
r.post_samples = post_samples;

T = t(2) - t(1); % Deduce frame rate from provided time

r.t_kernel = T*(-pre_samples:post_samples);
r.num_dofs = length(r.t_kernel);

% trace = trace - mean(trace);
X = ctxstr.analysis.regress.generate_temporally_offset_regressors(trace, pre_samples, post_samples);
r.X_by_trial = ctxstr.core.parse_into_trials(X, t, trials);