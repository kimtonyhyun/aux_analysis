
%% Analysis #3: Dimensionality

K = 20;
[ctx_traces_hat, ctx_hat_info] = compute_lowrank_traces(cont_ctx_traces, K);
[str_traces_hat, str_hat_info] = compute_lowrank_traces(cont_str_traces, K);

%%

font_size = 18;
marker_size = 12;
x_offset = 0.1;

x_lims = [0 K+1];

subplot(121);
plot(ctx_hat_info.ranks, ctx_hat_info.model_error, 'k.-', 'MarkerSize', marker_size);
hold on;
plot(str_hat_info.ranks, str_hat_info.model_error, 'm.-', 'MarkerSize', marker_size);
hold off;
xlim(x_lims);
ylim([0 1]);
grid on;
legend(sprintf('Ctx (%d neurons)', num_ctx_cells),...
       sprintf('Str (%d neurons)', num_str_cells),...
       'Location', 'NorthEast');
ylabel('Normalized model error');
title(dataset_name);
xlabel('Rank of approximation');
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);

subplot(122);
cla;
hold on;
for k = 1:K
    neuron_R2s = ctx_hat_info.neuron_R2s(:,k);
    vals = prctile(neuron_R2s, [25 50 75]);
    plot(k*[1 1], vals([1 end]), 'k-');
    plot(k, vals(2), 'k.', 'MarkerSize', marker_size);
    
    neuron_R2s = str_hat_info.neuron_R2s(:,k);
    vals = prctile(neuron_R2s, [25 50 75]);
    plot(k*[1 1]+x_offset, vals([1 end]), 'm-');
    plot(k+x_offset, vals(2), 'm.', 'MarkerSize', marker_size);
end
hold off;
grid on;
xlim(x_lims);
ylim([0 1]);
ylabel('Single-neuron R^2');
xlabel('Rank of approximation');
set(gca, 'FontSize', font_size);
set(gca, 'TickLength', [0 0]);

