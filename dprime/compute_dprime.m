function [d, d_approx, stats] = compute_dprime(F0, nu, DFF, tau)
% See Wilt et al. 2013 and its supplementary materials. Parameters:
% - F0: photons / sec
% - nu: Frame rate
% Below, we avoid taking the expansion of s_n. Thus, there is no 
% approximation, beyond the truncation of the summation index n.

% Faster computation
n = 1:1000; % max(n) >> tau*nu
sns = DFF*tau*nu*(exp(1/(tau*nu))-1)*exp(-n/(tau*nu));
mu0 = F0/nu*sum(log(1+sns)-sns);
mu1 = F0/nu*sum((1+sns).*log(1+sns)-sns);
var0 = F0/nu*sum(log(1+sns).^2);
var1 = F0/nu*sum((1+sns).*log(1+sns).^2);

d = (mu1-mu0)/sqrt(1/2*(var0+var1));

stats.tau_nu = tau * nu;
stats.sns = sns;
stats.mu0 = mu0;
stats.mu1 = mu1;
stats.var0 = var0;
stats.var1 = var1;

d_approx = DFF * sqrt(F0*tau/2);