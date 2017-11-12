function [pre_features, post_features] = run_logistic_regression(ds, cell_idx, modality)

if nargin < 3
    modality = 'mean_fluorescence';
end

trials = ds.get_switch_trials;

pre_trials = trials.constant_pre;
post_trials = trials.constant_post;

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
[train, test, inds] = split_train_test(pre_features, post_features, 0.7);

% Fit logistic regression to training data
%------------------------------------------------------------
w = fit_logistic_regression(train.X, train.y);

% Evaluate training accuracy
y_train_pred = make_prediction(w, train.X);
train_acc = sum(y_train_pred == train.y) / train.n;

% Decision boundary (the 1-D case)
f_db = -w(2)/w(1);

subplot(3,4,[5 6 7]);
draw_stem(x0(inds.pre.train), pre_features(inds.pre.train),...
          x1(inds.post.train), post_features(inds.post.train));
hold on;
plot(x_range, f_db*[1 1], 'k--');
hold off;
title(sprintf('Training: %d examples', train.n));

% Show the fitted sigmoid function as function of feature value
subplot(3,4,8);
f_cont = linspace(f_range(1), f_range(2));
h = sigmoid(w(1)*f_cont + w(2));

pred_pre = (h < 0.5);
pred_post = (h >= 0.5);

plot(h(pred_pre), f_cont(pred_pre), 'b');
hold on;
plot(h(pred_post), f_cont(pred_post), 'r');
plot([0 1], f_db*[1 1], 'k--');
hold off;
grid on;
ylim(f_range);
xlim([0 1]);
xlabel('P(post|x,w)');
title(sprintf('Train acc = %.1f%%', train_acc*100));

% Evaluate on training data
%------------------------------------------------------------
y_pred = make_prediction(w, test.X);
corr = (y_pred == test.y);
n_corr = sum(corr);
test_acc = n_corr / test.n;

subplot(3,4,[9 10 11]);
draw_stem(x0(inds.pre.test), pre_features(inds.pre.test),...
          x1(inds.post.test), post_features(inds.post.test));
hold on;
plot(x_range, f_db*[1 1], 'k--');
hold off;
title(sprintf('Test: %d examples, of which %d correctly predicted (%.0f%%)',...
    test.n, n_corr, test_acc*100));

x_test = [x0(inds.pre.test) x1(inds.post.test)];
for k = 1:test.n
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