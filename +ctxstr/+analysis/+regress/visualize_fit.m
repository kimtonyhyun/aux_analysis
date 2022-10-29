function visualize_fit(time_by_trial, train_trial_inds, test_trial_inds,...
    model, kernels, train_results, test_results,...
    t, reward_frames, motion_frames, velocity, accel, lick_rate)

sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.04, 0.04); % Gap, Margin-X, Margin-Y

lambdas = test_results.lambdas;
best_ind = test_results.best_ind;
best_lambda = lambdas(best_ind);
best_R2 = test_results.R2(best_ind);
best_bias = kernels{end}(best_ind);
clf;

l_lims = [min(lambdas) max(lambdas)];

ax_main = sp(5,3,1);
semilogx(lambdas, train_results.R2, '.-');
xlabel('Regularization weight, \lambda');
ylabel('Training set R^2');
grid on;
xlim(l_lims);

sp(5,3,2);
semilogx(lambdas, test_results.R2, '.-');
hold on;
plot(best_lambda, best_R2, 'mo');
hold off;
xlabel('\lambda');
ylabel({'Testing set R^2', '(Higher is better)'});
title(sprintf('Optimal R^2=%.4f', best_R2));
grid on;
xlim(l_lims);

w_null = train_results.w_null;
sp(5,3,3);
semilogx(lambdas, kernels{end}, '.-');
hold on;
plot(best_lambda, best_bias, 'mo');
plot(l_lims, w_null*[1 1], 'k--');
hold off;
xlabel('\lambda');
ylabel('Bias weight');
title(sprintf('Optimal bias=%.4f (\\pi=%.1f%%); Null bias=%.4f (\\pi=%.1f%%)',...
    best_bias, 100*sigmoid(best_bias),...
    w_null, 100*sigmoid(w_null)));
grid on;
xlim(l_lims);

% Plot behavioral regressors in time
%------------------------------------------------------------
ax_regressors = sp(5,1,2);
all_inds = union(train_trial_inds, test_trial_inds);
plot_traces_by_trial(...
    {velocity, t, [0 0.447 0.741]},...
    time_by_trial, all_inds,...
    t, reward_frames, motion_frames);
hold on;
plot(t([1 end]), [0 0], 'k:');
hold off;
ylabel('Velocity (norm.)');

% Plot training data fit in time
%------------------------------------------------------------
ax_train = sp(5,1,3);
t_train = ctxstr.core.concatenate_trials(time_by_trial, train_trial_inds);
plot_traces_by_trial(...
    {train_results.y', t_train, [0 0.5 0];...
     train_results.y_fits(:,best_ind)', t_train, 'm'},...
    time_by_trial, train_trial_inds,...
    t, reward_frames, motion_frames);
ylabel(sprintf('Training fit (%d trials)', length(train_trial_inds)));

% Plot testing data fit in time
%------------------------------------------------------------
ax_test = sp(5,1,4);
t_test = ctxstr.core.concatenate_trials(time_by_trial, test_trial_inds);
plot_traces_by_trial(...
    {test_results.y', t_test, [0 0.5 0];...
     test_results.y_fits(:,best_ind)', t_test, 'm'},...
    time_by_trial, test_trial_inds,...
    t, reward_frames, motion_frames);
ylabel(sprintf('Testing fit (%d trials)', length(test_trial_inds)));

linkaxes([ax_regressors ax_train ax_test], 'x');
xlim(t([1 end]));
xlabel('Trial');
set([ax_regressors ax_train ax_test], 'TickLength', [0 0]);
zoom xon;

% Plot kernels
%------------------------------------------------------------
num_regressors = length(model);

for k = 1:num_regressors
    sp(5, num_regressors, 4*num_regressors+k);
    r = model{k};
    best_kernel = kernels{k}(:,best_ind);
    stem(r.t_kernel, best_kernel, 'm.-');
    title(sprintf('%s (%s; %d dofs)', r.name, r.type, r.num_dofs), 'Interpreter', 'none');
    if r.num_dofs > 1
        xlim(r.t_kernel([1 end]));
    end
    grid on;
    xlabel('Time (s)');
    set(gca, 'TickLength', [0 0]);
    
    if k == 1
        ylabel('Kernel weights');
    end
end

subplot(ax_main); % So that title can be added externally

end % visualize_fit

% Generic function for plotting traces as a function of trial, where
% data(i,:) = {trace_i, t_i, color_i}.
% 
% Also indicates reward and motion onset frames by vertical bars
function plot_traces_by_trial(data,...
    time_by_trial, trial_inds_to_show,...
    t, reward_frames, motion_frames)

num_traces = size(data,1);
y_lims = [-0.1 1.1];

num_trials_to_show = length(trial_inds_to_show);
trial_start_times = zeros(1, num_trials_to_show);

hold on;
for m = 1:num_traces
    y_m = data{m,1};
    t_m = data{m,2};
    color_m = data{m,3};
    
    for k = 1:num_trials_to_show
        trial_ind = trial_inds_to_show(k);
        t_lims = time_by_trial{trial_ind}([1 end]);
        
        [y_mk, t_mk] = ctxstr.core.get_traces_by_time(y_m, t_m, t_lims);
        plot(t_mk, y_mk, '.-', 'Color', color_m);
    end
end

for k = 1:num_trials_to_show
    trial_ind = trial_inds_to_show(k);
    t_lims = time_by_trial{trial_ind}([1 end]);
          
    [rf_k, t_k] = ctxstr.core.get_traces_by_time(reward_frames, t, t_lims);
    plot_vertical_lines(t_k(rf_k), y_lims, 'b:');
    
    mf_k = ctxstr.core.get_traces_by_time(motion_frames, t, t_lims);
    plot_vertical_lines(t_k(mf_k), y_lims, 'r:');
    
    trial_start_times(k) = t_lims(1);
end
hold off;

ylim(y_lims);

% Label x-axis by trial index, rather than time
set(gca, 'XTick', trial_start_times);
set(gca, 'XTickLabel', trial_inds_to_show);

end
