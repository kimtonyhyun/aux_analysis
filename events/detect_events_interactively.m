function events = detect_events_interactively(trace_orig, varargin)

use_filter = true;
fps = 30;
cutoff_freq = [];
for i = 1:length(varargin)
    vararg = varargin{i};
    if ischar(vararg)
        switch lower(vararg)
            case 'fps'
                fps = varargin{i+1};
            case 'cutoff'
                cutoff_freq = varargin{i+1};
            case 'nofilter'
                use_filter = false;
        end
    end
end

% We'll for events in a smoothed version of the trace
% Default parameters comes from cerebellar processing, where we used
%   - 30 Hz sampling frequency
%   - 4 Hz cutoff frequency
if isempty(cutoff_freq)
    cutoff_freq = 4/30 * fps;
end
if use_filter
    fprintf('Applying LPF (fc=%.1f Hz) to trace...\n', cutoff_freq);
    trace = filter_trace(trace_orig, cutoff_freq, fps);
else
    trace = trace_orig;
end

% Basic trace properties
num_frames = length(trace);
trace_range = [min(trace) max(trace)];
trace_range = trace_range + 0.1*diff(trace_range)*[-1 1];

% Application state
state.x_anchor = 1;
state.x_range = min(1000, num_frames);
state.show_raw = true;
state.show_dots = false;

[events.threshold, stats] = estimate_baseline_threshold(trace);
events.auto = find_events(trace, events.threshold);
events.manual = [];

hfig = figure;
gui = setup_gui(hfig, num_frames, trace_range, stats, trace_orig);
redraw_threshold(gui);

% Interaction loop:
%------------------------------------------------------------
prompt = 'Event detector >> ';
resp = lower(strtrim(input(prompt, 's')));
val = str2double(resp);

while (1)
    if (~isnan(val)) % Is a number
        fprintf('  Number input not handled!\n');
    else % Not a number
        switch (resp)
            case 'q' % "quit"
                close(hfig);
                break;

            case 'z' % zoom in
                x_center = state.x_anchor + 1/2 * state.x_range;
                state.x_range = 0.5*state.x_range;
                state.x_anchor = x_center - 1/2 * state.x_range;
                redraw_local_window(gui);
                
            case 'o' % zoom out
                x_center = state.x_anchor + 1/2 * state.x_range;
                state.x_range = 2*state.x_range;
                state.x_anchor = x_center - 1/2 * state.x_range;
                redraw_local_window(gui);
                
            case 'r' % toggle raw trace
                state.show_raw = ~state.show_raw;
                if (state.show_raw)
                    set(gui.local_raw, 'Visible', 'on');
                else
                    set(gui.local_raw, 'Visible', 'off');
                end
                
            case 'd' % show dots
                state.show_dots = ~state.show_dots;
                if (state.show_dots)
                    set(gui.local_dots, 'Visible', 'on');
                else
                    set(gui.local_dots, 'Visible', 'off');
                end
                
            case 'x' % erase last event
                num_events = length(events.manual);
                if (num_events > 0)
                    events.manual = events.manual(1:num_events-1);
                    redraw_manual_events(gui);
                else
                    fprintf('  No events to remove!\n');
                end

            otherwise
                fprintf('  Sorry, could not parse "%s"\n', resp);
        end
    end
        
    resp = lower(strtrim(input(prompt, 's')));
    val = str2double(resp);
end % Main interaction loop

    function get_next_page(gui)
        current_end = state.x_anchor + state.x_range;
        if (current_end >= gui.num_frames)
            new_anchor = gui.num_frames - state.x_range + 1;
        else
            new_anchor = state.x_anchor + 0.1*state.x_range + 1;
        end

        state.x_anchor = new_anchor;
        redraw_local_window(gui);
    end % get_next_page

    function get_prev_page(gui)
        new_anchor = state.x_anchor - (0.1*state.x_range + 1);
        state.x_anchor = max(1, new_anchor);
        redraw_local_window(gui);
    end % get_prev_page

    function gui = setup_gui(hf, num_frames, trace_range, trace_stats, trace_orig)
        % Display parameters kept around for convenience
        gui.num_frames = num_frames;
        gui.trace_range = trace_range;
        
        % Setup the GLOBAL trace plot
        gui.global = subplot(2,5,1:4);
        gui.global_rect = rectangle('Position',[state.x_anchor trace_range(1) state.x_range diff(trace_range)],...
                  'EdgeColor', 'none',...
                  'FaceColor', 'c', 'HitTest', 'off');
        hold on;
        plot(trace, 'k', 'HitTest', 'off');
        gui.global_thresh = plot([1 num_frames], events.threshold*[1 1], 'm--', 'HitTest', 'off');
        gui.global_auto = plot(-Inf, -1, 'm.', 'HitTest', 'off');
        gui.global_manual = plot(-Inf, -1, 'r.', 'HitTest', 'off');
        hold off;
        box on;
        xlim([1 num_frames]);
        ylim(trace_range);
        xlabel('Frame');
        ylabel('Fluorescence');
        
        % Setup the HISTOGRAM plot
        gui.histogram = subplot(2,5,5);
        semilogy(trace_stats.hist_centers, trace_stats.hist_counts, 'k.', 'HitTest', 'off');
        xlim(trace_range);
        hold on;
        count_range = [1 10^ceil(log10(max(trace_stats.hist_counts)))]; % First power of 10 that exceeds the maximum count
        ylim(count_range);
        for k = 1:size(trace_stats.percentiles,1)
            y = trace_stats.percentiles(k,2);
            plot(y*[1 1], count_range, 'Color', 0.5*[1 1 1], 'HitTest', 'off');
        end
        gui.histogram_thresh = plot(events.threshold*[1 1], count_range, 'm--', 'HitTest', 'off');
        hold off;
        view([90 90]);
        set(gui.histogram, 'XDir', 'Reverse');
        ylabel('Counts');

        % Setup the LOCAL trace plot
        gui.local = subplot(2,1,2);
        gui.local_raw = plot(trace_orig, 'Color', 0.6*[1 1 1], 'HitTest', 'off');
        hold on;
        plot(trace, 'k', 'HitTest', 'off');
        gui.local_dots = plot(trace, 'k.', 'HitTest', 'off');
        if state.show_raw
            set(gui.local_raw, 'Visible', 'on');
        else
            set(gui.local_raw, 'Visible', 'off');
        end
        if state.show_dots
            set(gui.local_dots, 'Visible', 'on');
        else
            set(gui.local_dots, 'Visible', 'off');
        end
        gui.local_dot = plot(-1,trace(1),'ro',...
            'MarkerFaceColor','r',...
            'MarkerSize',6,'HitTest','off');
        gui.local_bar = plot(-Inf*[1 1], trace_range, 'k--', 'HitTest', 'off');
        gui.local_thresh = plot([1 num_frames], events.threshold*[1 1], 'm--', 'HitTest', 'off');
        gui.local_auto = plot(-1, -1, 'm');
        gui.local_auto_amps = plot(-1, -1, 'm', 'LineWidth', 2);
        gui.local_manual = plot(-1, -1, 'r');
        hold off;
        ylim(trace_range);
        grid on;
        x_range = [state.x_anchor, state.x_anchor+state.x_range-1];
        xlim(x_range);
        xlabel('Frame');
        ylabel('Fluorescence');
        
        % Add GUI event listeners
        set(gui.global, 'ButtonDownFcn', {@global_plot_handler, gui});
        set(gui.histogram, 'ButtonDownFcn', {@histogram_handler, gui});
        set(gui.local, 'ButtonDownFcn', {@local_plot_handler, gui});
        set(hf, 'WindowButtonMotionFcn', {@track_cursor, gui});
        set(hf, 'WindowScrollWheelFcn', {@scroll_plot, gui});
        
        function track_cursor(~, e, gui)
            x = round(e.IntersectionPoint(1));
            if ((state.x_anchor<=x)&&(x<=state.x_anchor+state.x_range))
                if ((1<=x)&&(x<=gui.num_frames))                  
                    x = seek_localmax(trace, x);
                    set(gui.local_bar,'XData',x*[1 1]);
                    set(gui.local_dot,'XData',x,'YData',trace(x));
                end
            end
        end % track_cursor
        
        function scroll_plot(~, e, gui)
            if (e.VerticalScrollCount < 0) % Scroll up
                get_prev_page(gui);
            else
                get_next_page(gui);
            end
        end % scroll_plot
        
    end % setup_gui

    % Update the GUI
    %------------------------------------------------------------
    function redraw_local_window(gui)
        rect_pos = get(gui.global_rect, 'Position');
        rect_pos(1) = state.x_anchor;
        rect_pos(3) = state.x_range;
        set(gui.global_rect, 'Position', rect_pos);
        
        subplot(gui.local);
        xlim([state.x_anchor, state.x_anchor+state.x_range-1]);
    end % redraw_local_window

    function redraw_threshold(gui)        
        set(gui.global_thresh, 'YData', events.threshold*[1 1]);
        auto_peaks = events.auto(:,2)';
        set(gui.global_auto, 'XData', auto_peaks, 'YData', trace(auto_peaks));
        update_event_tally(gui);
        
        set(gui.histogram_thresh, 'XData', events.threshold*[1 1]);
        set(gui.local_thresh, 'YData', events.threshold*[1 1]);
        
        % Note: NaN's break connections between line segments
        num_auto_events = size(events.auto, 1);
        X = kron(auto_peaks, [1 1 NaN]);
        Y = repmat([gui.trace_range NaN], 1, num_auto_events);
        set(gui.local_auto, 'XData', X, 'YData', Y);
        
        % Draw event amplitudes
        Y = zeros(3, num_auto_events);
        Y(1,:) = trace(events.auto(:,2));
        Y(2,:) = trace(events.auto(:,1));
        Y(3,:) = NaN;
        set(gui.local_auto_amps, 'XData', X, 'YData', Y(:));
    end % redraw_threshold

    function redraw_manual_events(gui)
        set(gui.global_manual, 'XData', events.manual, 'YData', trace(events.manual));
        
        X = kron(events.manual', [1 1 NaN]);
        Y = repmat([gui.trace_range NaN], 1, length(events.manual));
        set(gui.local_manual, 'XData', X, 'YData', Y);
        
        update_event_tally(gui);
    end % redraw_manual_events

    function update_event_tally(gui)
        num_auto = size(events.auto,1);
        num_manual = length(events.manual);
        
        subplot(gui.global);
        title(sprintf('Num events: %d (auto), %d (manual)', num_auto, num_manual));
    end % update_event_tally

    % Event handlers for mouse input
    %------------------------------------------------------------
    function global_plot_handler(~, e, gui)
        switch e.Button
            case 1 % Left click -- Move the local viewpoint
                x = round(e.IntersectionPoint(1));
                if ((1<=x) && (x<=gui.num_frames))
                    state.x_anchor = x - state.x_range/2;
                    redraw_local_window(gui);
                else
                    fprintf('\n  Not a valid frame for this trace!\n');
                end
                
            case 3 % Right click -- Set threshold
                t = e.IntersectionPoint(2);
                events.threshold = t;
                events.auto = find_events(trace, t);
                redraw_threshold(gui);
        end
    end % global_plot_handler

    function histogram_handler(~, e, gui)
        switch e.Button
            case 1 % Left click -- Set threshold
                t = e.IntersectionPoint(1);
                events.threshold = t;
                events.auto = find_events(trace, t);
                redraw_threshold(gui);
            case 3 % Right click
                
        end
    end % histogram_handler

    function local_plot_handler(~, e, gui)
        switch e.Button
            case 1 % Left click
                x = round(e.IntersectionPoint(1));
                if ((1<=x) && (x<=gui.num_frames))
                    x = seek_localmax(trace,x);
                    % Don't make duplicate events
                    auto_peaks = events.auto(:,2);
                    if ~ismember(x, auto_peaks) && ~ismember(x, events.manual)
                        events.manual = [events.manual; x];
                        redraw_manual_events(gui);
                    end
                else
                    fprintf('\n  Not a valid event for this trace!\n');
                end
                
            case 3 % Right click
                
        end
    end % local_plot_handler

end % detect_events_interactively
