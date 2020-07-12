clear all;

% Given a single spike detection rate at high zoom (20 um FOV) for a 5%
% false positive rate, what is the expected single spike detection rate at
% low zoom (400 um)?
%
% Data from Huang et al. (2020):
%   https://www.biorxiv.org/content/10.1101/788802v2

% Latest version of Huang et al. claims 54% single-spike detection rate at
% 5% false positive rate under high zoom conditions in Cux2-f neurons.
sdr_highzoom = 0.54;
fpr = 0.05;

z0 = icdf('Normal', 1-fpr, 0, 1);
z1 = icdf('Normal', 1-sdr_highzoom, 0, 1);

d_highzoom = z0 - z1; % This is discriminability index d' for high zoom

% Estimate F0 for the high zoom condition, using approximate d' formula
%------------------------------------------------------------
DFF = 0.19; % GCaMP6f, Chen et al. 2013
tau = 0.142 / log(2); % GCaMP6f (s)

F0_highzoom = 2/tau * (d_highzoom/DFF)^2;

% Estimate the d' value for low zoom, using approximate d' formula
% - Low zoom FOV is 400 um
% - High zoom FOV is 20 um
%------------------------------------------------------------
d_lowzoom = d_highzoom / sqrt(20);

sdr_lowzoom = 1-normcdf(z0-d_lowzoom);