function browse_corrlist(corrlist, ds1, ds2)

y_offset = 0.0;
y_range = [-0.1 1.1+y_offset];

% Set up figure
%------------------------------------------------------------
h_traces = subplot(311);
tr_i = ds1.get_trace(1, 'norm'); % Any trace. Needed for setup.
h_tr1 = plot(tr_i);
hold on;
h_tr2 = plot(tr_i);
for k = 2:ds1.num_trials % Trial boundaries
    plot(ds1.trial_indices(k,1)*[1 1], y_range, 'k:');
end
hold off;
xlim([1 length(tr_i)]);
ylim(y_range);
set(gca, 'TickLength', [0 0]);

% h_cellmap1 = subplot(3,3,[4 7]);
% h_cellmap2 = subplot(3,3,[5 8]);

subplot(3,3,[6 9]);
h_corr = plot(tr_i, tr_i, '.k');
xlim([-0.1 1.1]);
ylim([-0.1 1.1]);
grid on;
axis square;

for k = 1:size(corrlist, 1)
    i = corrlist(k,1);
    j = corrlist(k,2);
    c = corrlist(k,3);
    
    tr_i = ds1.get_trace(i, 'norm');
    tr_j = ds2.get_trace(j, 'norm');
    
    subplot(h_traces);
    h_tr1.YData = tr_i + y_offset; 
    h_tr2.YData = tr_j;
    xlim([1 length(tr_i)]);
    ylim(y_range);
    title(sprintf('Corr=%.4f', c));
    
    h_corr.XData = tr_i;
    h_corr.YData = tr_j;

%     % Show cell maps
%     subplot(h_cellmap1);
%     ds1.highlight_cell(i);
%     subplot(h_cellmap2);
%     ds2.highlight_cell(j);
%     zoom on; % Undo 'datacursormode' within 'highlight_cell'
    
    drawnow;
    pause;
end