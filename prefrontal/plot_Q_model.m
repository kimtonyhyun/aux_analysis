function plot_Q_model(Q, p)

num_trials = size(Q,3);

subplot(2,2,1);
plot(squeeze(Q(1,1,:)));
hold on;
plot(squeeze(Q(1,2,:)),'r');
hold off;
title('State = 1 (East)');
xlim([1 num_trials]);
ylabel('Q(s=1,a)');
ylim([-0.1 1.1]);
legend('a = 1 (North)', 'a = 2 (South)', 'Location', 'Best');

subplot(2,2,3);
plot(squeeze(p(1,1,:)));
hold on;
plot(squeeze(p(1,2,:)),'r');
hold off;
xlim([1 num_trials]);
xlabel('Trials');
ylabel('Pr(a|s=1)');
ylim([-0.1 1.1]);
legend('a = 1 (North)', 'a = 2 (South)', 'Location', 'Best');

subplot(2,2,2);
plot(squeeze(Q(2,1,:)));
hold on;
plot(squeeze(Q(2,2,:)),'r');
hold off;
title('State = 2 (West)');
xlim([1 num_trials]);
ylabel('Q(s=2,a)');
ylim([-0.1 1.1]);
legend('a = 1 (North)', 'a = 2 (South)', 'Location', 'Best');

subplot(2,2,4);
plot(squeeze(p(2,1,:)));
hold on;
plot(squeeze(p(2,2,:)),'r');
hold off;
xlim([1 num_trials]);
xlabel('Trials');
ylabel('Pr(a|s=2)');
ylim([-0.1 1.1]);
legend('a = 1 (North)', 'a = 2 (South)', 'Location', 'Best');