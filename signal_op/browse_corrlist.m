function browse_corrlist(corrlist, ds1, ds2, varargin)

ds_labels = {'ds1', 'ds2'};
frames = [];
for k = 1:length(varargin)
    if ischar(varargin{k})
        switch lower(varargin{k})
            case {'name', 'names'}
                if iscell(varargin{k+1})
                    ds_labels = varargin{k+1};
                elseif ischar(varargin{k+1})
                    ds_labels = {varargin{k+1}};
                end
            case 'frames' % Indicate frames with vertical bar
                frames = varargin{k+1};
        end
    end
end

% Display parameters
y_offset = 0.0;
y_range = [-0.1 1.1+y_offset];

color1 = [0 0.4470 0.7410];
color2 = [0.85 0.325 0.098];

% Are we displaying correlations within one ds?
same_ds = (ds1 == ds2);

% Set up figure
%------------------------------------------------------------
h_fig = figure;
h_traces = subplot(311);
tr = ds1.get_trace(1, 'norm'); % Any trace. Just needed for setup.
h_tr1 = plot(tr);
hold on;
h_tr2 = plot(tr);
for k = 2:ds1.num_trials % Trial boundaries
    plot(ds1.trial_indices(k,1)*[1 1], y_range, 'k:');
end
for k = 1:length(frames) % Extra vertical markers
    plot(frames(k)*[1 1], y_range, 'b:');
end
hold off;
legend(ds_labels, 'Location', 'NorthWest');
xlim([1 length(tr)]);
ylim(y_range);
set(gca, 'TickLength', [0 0]);

if ~same_ds
    h_cellmap1 = subplot(3,3,[4 7]);
    h_cellmap2 = subplot(3,3,[5 8]);
    subplot(3,3,[6 9]);
else
    h_cellmap1 = subplot(3,2,[3 5]);
    subplot(3,2,[4 6]);
end
h_corr = plot(tr, tr, '.k');
xlabel(ds_labels{1});
if same_ds
    ylabel(ds_labels{1});
else
    ylabel(ds_labels{2});
end
xlim([-0.1 1.1]);
ylim([-0.1 1.1]);
grid on;
axis square;

% Interactive loop
%------------------------------------------------------------
num_pairs = size(corrlist, 1);

idx = 1; 
while (1)
    update_fig(idx);
    
    prompt = sprintf('Browse_corrlist (%d of %d) >> ', idx, num_pairs);
    resp = strtrim(input(prompt, 's'));
    
    val = str2double(resp);
    if (~isnan(val)) % Is a number
        if (1 <= val) && (val <= num_pairs)
            idx = val;
        end
    else
        resp = lower(resp);
        if isempty(resp)
            idx = idx + 1;
            idx = min(num_pairs, idx);
        else
            switch resp(1)
                case 'p' % Previous
                    idx = idx - 1;
                    idx = max(1, idx);

                case 'q' % Exit
                    close(h_fig);
                    break;

                otherwise
                    fprintf('  Could not parse "%s"\n', resp);
            end
        end
    end
end % while (1)

    function update_fig(k)
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
        if ~same_ds
            title(sprintf('%s cell=%d\n%s cell=%d\ncorr=%.4f',...
                    ds_labels{1}, i, ds_labels{2}, j, c));
        else
            title(sprintf('%s cells=[%d, %d]\ncorr=%.4f',...
                    ds_labels{1}, i, j, c));
        end

        h_corr.XData = tr_i;
        h_corr.YData = tr_j;

        % Show cell maps
        if ~same_ds
            subplot(h_cellmap1);
            draw_cellmap(ds1, {i, color1});
            title(ds_labels{1});
            subplot(h_cellmap2);
            draw_cellmap(ds2, {j, color2});
            title(ds_labels{2});
        else
            subplot(h_cellmap1);
            draw_cellmap(ds1, {i, color1; j, color2});
            title(ds_labels{1});
        end
    end % update_fig

end % browse_corrlist



function draw_cellmap(ds, filled_cells)
    % 'filled_cells' is a N x 2 cell array where the i-th row indicates:
    %   - filled_cells{i,1}: Cell index
    %   - filled_cells{i,2}: Color to fill the cell with
    
    imagesc(ds.cell_map_ref_img);
    set(gca, 'XTickLabel', []);
    set(gca, 'YTickLabel', []);
    axis image;
    colormap gray;
    hold on;
    for cell_ind = find(ds.is_cell)
        boundary = ds.cells(cell_ind).boundary;
        plot(boundary(:,1), boundary(:,2), 'g');
    end
    
    num_filled = size(filled_cells, 1);
    for k = 1:num_filled
        cell_ind = filled_cells{k,1};
        cell_color = filled_cells{k,2};
        
        boundary = ds.cells(cell_ind).boundary;
        fill(boundary(:,1), boundary(:,2), cell_color);
    end
    hold off;
end