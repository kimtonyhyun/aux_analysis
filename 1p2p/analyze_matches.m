function analyze_matches(matched, non_matched)

green = rgb('Green');
red = rgb('Red');
marker_size = 18;

plot(matched(:,4), matched(:,5), '.', 'Color', green, 'MarkerSize', marker_size);
hold on;
plot(non_matched(:,4), non_matched(:,5), '.', 'Color', red, 'MarkerSize', marker_size);
hold off;

xlim([0 1]);
ylim([0 1]);
axis square;
grid on;

xlabel('Fraction of frames with good fit');
ylabel('Fraction variance explained');
