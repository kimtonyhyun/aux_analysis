function [pre_features, post_features] = run_logistic_regression(ds, cell_idx, modality)

if nargin < 3
    modality = 'mean_fluorescence';
end

trials = ds.get_switch_trials;

pre_trials = trials.constant_pre;
post_trials = trials.constant_post;
true_trial_inds = [pre_trials; post_trials];

num_pre = length(pre_trials);
num_post = length(post_trials);

pre = compute_features(ds, cell_idx, pre_trials);
post = compute_features(ds, cell_idx, post_trials);

pre_features = getfield(pre, modality); %#ok<*GFLD>
post_features = getfield(post, modality);
f_range = compute_ylim(pre_features, post_features);

x0 = 1:num_pre;
x1 = num_pre + (1:num_post);
x_range = [1 num_pre+num_post];
tick_inds = x_range(1):5:x_range(end);

% Draw all data
%------------------------------------------------------------
subplot(3,4,[1 2 3]);
draw_stem(x0, pre_features, x1, post_features);
title(sprintf('Cell %d: %d (pre) + %d (post) = %d examples',...
        cell_idx, num_pre, num_post, num_pre + num_post));

subplot(3,4,4);
grouping = false(num_pre+num_post,1); grouping(num_pre+1:end) = true;
boxplot([pre_features; post_features], grouping);
ylim(f_range);
grid on;
xticklabels({'Pre', 'Post'});
    
% Select and show training data
%------------------------------------------------------------
training_frac = 0.7;
num_pre_train = round(training_frac * num_pre);
num_pre_test = num_pre - num_pre_train;
num_post_train = round(training_frac * num_post);
num_post_test = num_post - num_post_train;

pre_train = randperm(num_pre) <= num_pre_train;
pre_test = ~pre_train;
post_train = randperm(num_post) <= num_post_train;
post_test = ~post_train;

% Fit logistic regression to training data
%------------------------------------------------------------
f_train_pre = pre_features(pre_train,:);
f_train_post = post_features(post_train,:);
f_train = [f_train_pre; f_train_post];
y_train = [zeros(num_pre_train,1); ones(num_post_train,1)]; % Note: 0 <==> Pre, 1 <==> Post
n_train = length(y_train);

w = fit_logistic_regression(f_train, y_train);

% Evaluate training accuracy
y_train_pred = make_prediction(w, f_train);
train_acc = sum(y_train_pred == y_train) / n_train;

% Decision boundary, for the special case of single feature
f_db = -w(2)/w(1);

subplot(3,4,[5 6 7]);
draw_stem(x0(pre_train), pre_features(pre_train),...
          x1(post_train), post_features(post_train));
hold on;
plot(x_range, f_db*[1 1], 'k--');
hold off;
title(sprintf('Training: %d (pre) + %d (post) = %d examples',...
    num_pre_train, num_post_train, num_pre_train + num_post_train));

% Show the fitted sigmoid function as function of feature value
subplot(3,4,8);
f_cont = linspace(f_range(1), f_range(2));
h = sigmoid(w(1)*f_cont + w(2));

pred_pre = (h < 0.5);
pred_post = (h >= 0.5);

plot(h(pred_pre), f_cont(pred_pre), 'b');
hold on;
plot(h(pred_post), f_cont(pred_post), 'r');
plot(0.5, f_db, 'k.', 'MarkerSize', 12);
plot([0 1], f_db*[1 1], 'k--');
% Show how the training data fall on the sigmoid
h_train_pre = sigmoid(w(1)*f_train_pre + w(2));
plot(h_train_pre, f_train_pre, 'b.');
h_train_post = sigmoid(w(1)*f_train_post + w(2));
plot(h_train_post, f_train_post, 'r.');
hold off;
grid on;
ylim(f_range);
xlim([0 1]);
xlabel('P(post|x,w)');
% ylabel(modality, 'Interpreter', 'none');
title(sprintf('Sigmoid fit: Train acc = %.1f%%', train_acc*100));

% Evaluate on training data
%------------------------------------------------------------
f_test = [pre_features(pre_test,:); post_features(post_test,:)];
y_test = [zeros(num_pre_test,1); ones(num_post_test,1)];
n_test = length(y_test);

y_pred = make_prediction(w, f_test);
corr = y_pred == y_test;
n_corr = sum(corr);
test_acc = n_corr / n_test;

subplot(3,4,[9 10 11]);
draw_stem(x0(pre_test), pre_features(pre_test),...
          x1(post_test), post_features(post_test));
hold on;
plot(x_range, f_db*[1 1], 'k--');
hold off;
title(sprintf('Test: %d (pre) + %d (post) = %d examples, of which %d correctly predicted (%.0f%%)',...
    num_pre_test, num_post_test, n_test, n_corr, test_acc*100));

x_test = [x0(pre_test) x1(post_test)];
for k = 1:n_test
    if corr(k)
        corr_color = 'g';
    else
        corr_color = 'r';
    end
    rectangle('Position', [x_test(k)-0.5 f_range(1) 1 0.05*diff(f_range)],...
              'FaceColor', corr_color);
end

    function draw_stem(x_pre, y_pre, x_post, y_post)
        stem(x_pre, y_pre, 'b.');
        hold on;
        stem(x_post, y_post, 'r.');
        hold off;
        grid on;
        xlim(x_range);
        ylim(f_range);
        xticks(tick_inds);
        xticklabels(num2cell(true_trial_inds(tick_inds)));
        xlabel('Trial index');
        ylabel(modality, 'Interpreter', 'none');
    end % draw_stem

end % run_logistic_regression

function y_range = compute_ylim(pre_vals, post_vals)
    all_vals = [pre_vals(:); post_vals(:)];
    m = min(min(all_vals), 0);
    M = max(all_vals);
    
    if (m ~= M)
        y_range = [m M] + 0.1*(M-m)*[-1 1];
    else
        y_range = m + [-0.5 0.5];
    end
end