% Vary pre/post temporal support for a single regressor, and visualize the
% effect on the resulting kernel, R^2, lambda-plots.

pre_vals = 0:5:30;
post_vals = 0:5:60;

cell_idx = 10;
lambdas = 0:0.25:20;

% Preallocate results
num_pre = length(pre_vals);
num_post = length(post_vals);

t_kernels = cell(num_pre, num_post);
kernels = cell(num_pre, num_post);

test_R2_plots = cell(num_pre, num_post);
opt_lambdas = zeros(num_pre, num_post);
opt_R2s = zeros(num_pre, num_post);
bias_weights = zeros(num_pre, num_post);

tic;
for i = 1:num_pre
    pre_val = pre_vals(i);
    for j = 1:num_post
        post_val = post_vals(j);
        
        % Define model
        velocity_regressor = ctxstr.analysis.regress.define_regressor(...
            'velocity', velocity, pre_val, post_val, t, trials);
        model = {velocity_regressor};
        t_kernels{i,j} = model{1}.t_kernel;
        
        [k, train_results, test_results] = ctxstr.analysis.regress.fit_neuron(...
            binned_str_traces_by_trial, cell_idx,...
            model,...
            train_trial_inds, test_trial_inds, lambdas);
        [~, best_ind] = max(test_results.R2);
        kernels{i,j} = k{1}(:,best_ind);
        bias_weights(i,j) = k{end}(best_ind);
        
        test_R2_plots{i,j} = test_results.R2;
        opt_lambdas(i,j) = test_results.lambdas(best_ind);
        opt_R2s(i,j) = test_results.R2(best_ind);
    end
end
t_opt = toc;
fprintf('Completed in %.1f s!\n', t_opt);

%%

clf;

subplot(3,2,1);
imagesc(post_vals, pre_vals, opt_R2s);
set(gca, 'XTick', post_vals);
set(gca, 'YTick', pre_vals);
xlabel('POST temporal support');
ylabel('PRE temporal support');
title('Test R^2');
colorbar;

subplot(3,2,2);
hold on;
for i = 1:num_pre
    for j = 1:num_post
        plot(t_kernels{i,j}, kernels{i,j}, 'k.-');
    end
end
hold off;
grid on;
xlabel('Time');
ylabel('Kernel weights');

subplot(3,2,3);
imagesc(post_vals, pre_vals, opt_lambdas);
set(gca, 'XTick', post_vals);
set(gca, 'YTick', pre_vals);
xlabel('POST temporal support');
ylabel('PRE temporal support');
title('\lambda_{opt}');
colorbar;

subplot(3,2,4);
hold on;
for i = 1:num_pre
    for j = 1:num_post
        plot(lambdas, test_R2_plots{i,j} - opt_R2s(i,j), 'k.-');
        plot(opt_lambdas(i,j), 0, 'ro');
    end
end
hold off;
grid on;
xlabel('\lambda');
ylabel('Test R^2 - R^2_{opt}');

subplot(3,2,5);
imagesc(post_vals, pre_vals, bias_weights);
set(gca, 'XTick', post_vals);
set(gca, 'YTick', pre_vals);
xlabel('POST temporal support');
ylabel('PRE temporal support');
title('Bias weights');
colorbar;

subplot(3,2,6);
imagesc(post_vals, pre_vals, sigmoid(bias_weights));
set(gca, 'XTick', post_vals);
set(gca, 'YTick', pre_vals);
xlabel('POST temporal support');
ylabel('PRE temporal support');
title('\pi_{bias}');
colorbar;