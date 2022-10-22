function [nll_null, w_null] = compute_null_model(y)
    n = length(y) + 2; % Pretend we observed 0 and 1 at least once; "Laplacian smoothing"
    m = sum(y) + 1;
    w_null = log(m/(n-m));
    nll_null = ctxstr.analysis.regress.bernoulli_nll(w_null, ones(size(y)), y);
end