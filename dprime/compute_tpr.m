function tpr = compute_tpr(dprime, fpr)
% Compute the true positive rate (TPR) at a specified false positive rate
% (FPR) level, given a discriminability index d'

% Let the 0 class be represented by N(0,1). Compute the z threshold
% corresponding to the given fpr
z0 = icdf('Normal', 1-fpr, 0, 1);

% The z-value is then computed relative to the mean of the 1 class, which
% is represented by N(dprime, 1)
z1 = z0 - dprime;

% Compute the TPR with respect to the 1 class
tpr = 1 - normcdf(z1);