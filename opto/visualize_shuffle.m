function visualize_shuffle(info)

% Unpack
score_type = info.settings.score_type;
mean_scores = info.results.full_stats.mean_scores; % [Laser-off Laser-on]
distrs = info.results.full_stats.distr; % [5th-percentile median 95-th percentile]
effect_type = info.results.full_stats.effect;
num_cells = info.results.num_cells;
num_inhibited = info.results.num_inhibited;
num_disinhibited = info.results.num_disinhibited;

[~, sorted_inds] = sort(distrs(:,2));
figure;
hold on;
for k = 1:num_cells
    cell_idx = sorted_inds(k);
    plot(k*[1 1], distrs(cell_idx,[1 end]), 'k-');
    plot(k, distrs(cell_idx,2), 'k.');
    switch effect_type(cell_idx)
        case '-'
            true_color = 'k';
        case 'inhibited'
            true_color = 'b';
        case 'disinhibited'
            true_color = 'r';
    end
    plot(k, mean_scores(cell_idx,2), 'x', 'Color', true_color);
end
hold off;
xlim([0 num_cells+1]);
xlabel(sprintf('Sorted cells (%d total)', num_cells));
ylabel(strrep(score_type,'_','\_'));
grid on;
legend('Shuffle distribution (5th-95th)', 'Shuffle median', 'Unshuffled (true) measurement',...
       'Location', 'NorthWest');
title(sprintf('%s: Inhibited (%d; blue), Disinhibited (%d; red)',...
    info.dataset_name, num_inhibited, num_disinhibited));