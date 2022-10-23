function visualize_fit(time_by_trial, train_trial_inds, test_trial_inds,...
    model, kernels, train_results, test_results,...
    t, reward_frames, motion_frames, velocity)

lambdas = test_results.lambdas;
[~, best_ind] = max(test_results.R2);
best_lambda = lambdas(best_ind);
best_R2 = test_results.R2(best_ind);
best_bias = kernels{end}(best_ind);
clf;

subplot(4,3,1);
plot(lambdas, train_results.R2, '.-');
xlabel('Regularization weight, \lambda');
ylabel('Training set R^2');
grid on;

subplot(4,3,2);
plot(lambdas, test_results.R2, '.-');
hold on;
plot(best_lambda, best_R2, 'mo');
hold off;
xlabel('\lambda');
ylabel({'Testing set R^2', '(Higher is better)'});
title(sprintf('Optimal R^2=%.4f', best_R2));
grid on;

subplot(4,3,3);
plot(lambdas, kernels{end}, '.-');
hold on;
plot(best_lambda, best_bias, 'mo');
hold off;
xlabel('\lambda');
ylabel('Bias weight');
title(sprintf('Optimal bias=%.4f (\\pi=%.1f%%)',...
    best_bias, 100*sigmoid(best_bias)));
grid on;

% Plot training data fit in time
%------------------------------------------------------------
ax_train = subplot(4,1,2);
plot_fit(train_results.y',...
         train_results.y_fits(:,best_ind)',...
         time_by_trial, train_trial_inds,...
         best_bias,...
         t, reward_frames, motion_frames, velocity);
ylabel('Training fit');

% Plot testing data fit in time
%------------------------------------------------------------
ax_test = subplot(4,1,3);
plot_fit(test_results.y',...
         test_results.y_fits(:,best_ind)',...
         time_by_trial, test_trial_inds,...
         best_bias,...
         t, reward_frames, motion_frames, velocity);
ylabel('Test fit');

linkaxes([ax_train ax_test], 'x');
xlim(t([1 end]));
xlabel('Trial');
set([ax_train ax_test], 'TickLength', [0 0]);
zoom xon;

% Plot kernels
%------------------------------------------------------------
num_regressors = length(model);

for k = 1:num_regressors
    subplot(4, num_regressors, 3*num_regressors+k);
    r = model{k};
    stem(r.t_kernel, kernels{k}(:,best_ind), 'm.-');
    title(sprintf('%s (%d dofs)', r.name, r.num_dofs), 'Interpreter', 'none');
    if r.num_dofs > 1
        xlim(r.t_kernel([1 end]));
    end
    grid on;
    xlabel('Time (s)');
 
    
    if k == 1
        ylabel('Kernel weights');
    end
end

end % visualize_fit

function plot_fit(y, y_fit, time_by_trial, trial_inds_to_show,...
    bias_weight,...
    t, reward_frames, motion_frames, velocity)

y_lims = [-0.1 1.1];
t_y = ctxstr.core.concatenate_trials(time_by_trial, trial_inds_to_show);

num_trials_to_show = length(trial_inds_to_show);
trial_start_times = zeros(1, num_trials_to_show);

hold on;
for k = 1:num_trials_to_show
    trial_ind = trial_inds_to_show(k);
    t_lims = time_by_trial{trial_ind}([1 end]);
    [y_k, t_k] = ctxstr.core.get_traces_by_time(y, t_y, t_lims);
    y_fit_k = ctxstr.core.get_traces_by_time(y_fit, t_y, t_lims);
    
    plot(t_k, y_k, '.-', 'Color', [0 0.5 0]);
    plot(t_k, y_fit_k, 'm.-');
    
%     v_k = ctxstr.core.get_traces_by_time(velocity, t, t_lims);
%     plot(t_k, v_k, 'b.-');
    
    rf_k = ctxstr.core.get_traces_by_time(reward_frames, t, t_lims);
    plot_vertical_lines(t_k(rf_k), y_lims, 'b:');
    
    mf_k = ctxstr.core.get_traces_by_time(motion_frames, t, t_lims);
    plot_vertical_lines(t_k(mf_k), y_lims, 'r:');
    
    trial_start_times(k) = t_lims(1);
end
plot(t([1 end]), sigmoid(bias_weight)*[1 1], 'k--');
hold off;

ylim(y_lims);

% Label x-axis by trial index, rather than time
set(gca, 'XTick', trial_start_times);
set(gca, 'XTickLabel', trial_inds_to_show);

end



