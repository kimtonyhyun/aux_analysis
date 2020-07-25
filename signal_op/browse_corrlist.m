function browse_corrlist(corrlist, ds1, ds2, varargin)

% Default settings
app_name = 'Browse corrlist';
trace_norm_method = 'norm';
ds_labels = {'ds1', 'ds2'};
frames = [];

color1 = [0 0.4470 0.7410];
color2 = [0.85 0.325 0.098];

% Different application "modes":
%   - "standard": compare correlations across two arbitrary DaySummaries
%   - "same_ds": compare correlations within a DaySummary
app_mode = 'standard';
if (ds1 == ds2)
    app_mode = 'same_ds';
end
num_pairs = size(corrlist, 1);

for k = 1:length(varargin)
    if ischar(varargin{k})
        switch lower(varargin{k})
            case 'zsc'
                trace_norm_method = 'zsc';
            case 'app_name'
                app_name = varargin{k+1};
            case {'name', 'names', 'ds_name', 'ds_names'}
                if iscell(varargin{k+1})
                    ds_labels = varargin{k+1};
                elseif ischar(varargin{k+1})
                    ds_labels = varargin(k+1);
                end
            case 'frames' % Indicate frames with vertical bar
                frames = varargin{k+1};
        end
    end
end


% Interactive loop
%------------------------------------------------------------
gui = setup_gui();

idx = 1; 
while (1)
    update_fig(idx, gui);
    
    prompt = sprintf('%s (%d of %d) >> ', app_name, idx, num_pairs);
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
                    close(gui.fig);
                    break;

                otherwise
                    fprintf('  Could not parse "%s"\n', resp);
            end
        end
    end
end % while (1)

    function gui_data = setup_gui()
        % Any trace. Needed for setup.
        tr = ds1.get_trace(1, 'norm');
        
        gui_data.fig = figure;
        
        % Traces subplot
        gui_data.traces_sp = subplot(311);
        gui_data.trace1 = plot(tr);
        hold on;
        gui_data.trace2 = plot(tr);
        for m = 2:ds1.num_trials % Trial boundaries
            xline(ds1.trial_indices(m,1), 'k:');
        end
        for m = 1:length(frames) % Extra vertical markers
            xline(frames(m), 'b:');
        end
        hold off;
        legend(ds_labels, 'Location', 'NorthWest');
        xlim([1 length(tr)]);
        xlabel('Frames');
        set(gca, 'TickLength', [0 0]);
        
        switch app_mode
            case 'standard'
                gui_data.cellmap1 = subplot(3,3,[4 7]);
                gui_data.cellmap2 = subplot(3,3,[5 8]);
                gui_data.corr_sp = subplot(3,3,[6 9]);
                gui_data.corr = plot(tr, tr, '.k');
                xlabel(ds_labels{1});
                ylabel(ds_labels{2});
                
            case 'same_ds'
                gui_data.cellmap1 = subplot(3,2,[3 5]);
                gui_data.corr_sp = subplot(3,2,[4 6]);
                gui_data.corr = plot(tr, tr, '.k');
                xlabel(ds_labels{1});
                xlabel(ds_labels{1});
        end
        
        switch trace_norm_method
            case 'norm'
                ticks = 0:0.1:1;
            case 'zsc'
                ticks = -50:5:50; % FIXME: Hard-coded   
        end
        set(gui_data.corr_sp, 'XTick', ticks);
        set(gui_data.corr_sp, 'YTick', ticks);
        grid(gui_data.corr_sp, 'on');
        axis(gui_data.corr_sp, 'equal');
        
    end % setup_standard_gui

    function update_fig(k, gui_data)
        i = corrlist(k,1);
        j = corrlist(k,2);
        c = corrlist(k,3);

        tr_i = ds1.get_trace(i, trace_norm_method);
        tr_j = ds2.get_trace(j, trace_norm_method);

        gui_data.trace1.YData = tr_i; 
        gui_data.trace2.YData = tr_j;
        xlim([1 length(tr_i)]);
        
        gui_data.corr.XData = tr_i;
        gui_data.corr.YData = tr_j;
        axis(gui_data.corr_sp, 'tight');
        
        switch app_mode
            case 'standard'
                title(gui_data.traces_sp,...
                    sprintf('%s cell=%d\n%s cell=%d\ncorr=%.4f',...
                    ds_labels{1}, i, ds_labels{2}, j, c));
                
                subplot(gui_data.cellmap1);
                draw_cellmap(ds1, {i, color1});
                title(ds_labels{1});
                subplot(gui_data.cellmap2);
                draw_cellmap(ds2, {j, color2});
                title(ds_labels{2});
                
            case 'same_ds'
                title(gui_data.traces_sp,...
                    sprintf('%s cells=[%d, %d]\ncorr=%.4f',...
                    ds_labels{1}, i, j, c));
                
                subplot(gui_data.cellmap1);
                draw_cellmap(ds1, {i, color1; j, color2});
                title(ds_labels{1});
        end

    end % update_fig

end % browse_corrlist

function draw_cellmap(ds, filled_cells, boundary_color)
    % 'filled_cells' is a N x 2 cell array where the i-th row indicates:
    %   - filled_cells{i,1}: Cell index
    %   - filled_cells{i,2}: Color to fill the cell with
    
    if ~exist('boundary_color', 'var')
        boundary_color = 'g';
    end
    
    imagesc(ds.cell_map_ref_img);
    set(gca, 'XTickLabel', []);
    set(gca, 'YTickLabel', []);
    axis image;
    colormap gray;
    hold on;
    for cell_ind = find(ds.is_cell)
        boundary = ds.cells(cell_ind).boundary;
        plot(boundary(:,1), boundary(:,2), 'Color', boundary_color);
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