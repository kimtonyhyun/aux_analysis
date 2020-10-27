function plot_tpr(fpr)
% Plot the TPR for a given FPR as a function of d'

ds = linspace(0.1, 20, 1e4);

tprs = compute_tpr(ds, fpr);

semilogx(ds, tprs);
xlabel('d prime');
ylabel(sprintf('True positive rate\nat FPR=%.3f', fpr));
xlim(ds([1 end]));
grid on;