function [d, d_approx] = compute_dprime(F0, nu, DFF, tau)
% See Wilt et al. 2013. Parameters:
% - F0: photons / sec
% - nu: Frame rate

N = 1000; % Acquired samples (just needs to be large; N/nu >> tau)

mu0 = 0;
var0 = 0;
mu1 = 0;
var1 = 0;

for n = 1:N
    sn = DFF*tau*nu*(exp(1/(tau*nu))-1)*exp(-n/(tau*nu));
    mu0 = mu0 + F0/nu*(log(1+sn) - sn);
    mu1 = mu1 + F0/nu*((1+sn)*log(1+sn) - sn);
    var0 = var0 + F0/nu*log(1+sn)^2;
    var1 = var1 + F0/nu*(1+sn)*log(1+sn)^2;
end

d = (mu1-mu0)/sqrt(1/2*(var0+var1));

d_approx = DFF * sqrt(F0*tau/2);