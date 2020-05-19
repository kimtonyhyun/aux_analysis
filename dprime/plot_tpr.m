% Plot the TPR for a given FPR as a function of d'

ds = linspace(0.01, 100, 1e4);

fpr = 0.05;
tprs = compute_tpr(ds, fpr);

loglog(ds, tprs);
xlabel('d prime');
ylabel(sprintf('True positive rate\nat FPR=%.3f', fpr));
grid on;