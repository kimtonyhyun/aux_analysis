function eventdata = detect_events_interactively(trace)

% Basic trace properties
num_frames = length(trace);
M = max(trace);
m = min(trace);
y_range = [m M] + 0.1*(M-m)*[-1 1];

% Set up GUI
zoom_factor = 0.5;
paging_factor = 0.25;

% Application state
state.x_anchor = 1;
state.x_range = min(1000, num_frames);
state.max_find = true;
state.max_find_method = 'localmax';
state.threshold = [];

events_auto = [];
events = [];

hf = figure;
draw_frame();

% Interaction loop:
%------------------------------------------------------------
prompt = 'Event detector >> ';
resp = lower(strtrim(input(prompt, 's')));
val = str2double(resp);

while (1)
    if (~isnan(val)) % Is a number
        if ((1 <= val) && (val <= num_frames))
            state.x_anchor = val;
            draw_frame();
        else
            fprintf('  Sorry, %d is not a frame number for this trace!\n', val);
        end
    else % Not a number
        switch (resp)
            case 'q' % "quit"
                close(hf);
                eventdata.manual = events;
                eventdata.auto = events_auto;
                eventdata.threshold = state.threshold;
                break;

            case {'z', 'i'} % zoom in
                state.x_range = zoom_factor*state.x_range;
                draw_frame();
                
            case {'u', 'o'} % zoom out
                state.x_range = 1/zoom_factor*state.x_range;
                draw_frame();

            case {'', 'n'} % Next
                get_next_page();

            case 'p' % Previous
                get_prev_page();
                
            case 'm' % "Max-find"
                if (state.max_find)
                    state.max_find = false;
                    fprintf('  Max-find turned OFF!\n');
                else
                    state.max_find = true;
                    fprintf('  Max-find turned ON!\n');
                end
                
            case 'x' % Erase last event
                num_events = size(events, 1);
                if (num_events > 0)
                    events = events(1:num_events-1,:);
                    draw_frame();
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

    function get_next_page()
        current_end = state.x_anchor + state.x_range;
        if (current_end >= num_frames)
            new_anchor = num_frames - state.x_range + 1;
        else
            new_anchor = state.x_anchor + paging_factor*state.x_range + 1;
        end

        state.x_anchor = new_anchor;
        draw_frame();
    end % get_next_page

    function get_prev_page()
        new_anchor = state.x_anchor - (paging_factor*state.x_range + 1);
        state.x_anchor = max(1, new_anchor);
        draw_frame();
    end % get_prev_page

    function draw_frame()
        clf;

        % Display the GLOBAL trace
        h_global = subplot(2,1,1);
        rectangle('Position',[state.x_anchor y_range(1) state.x_range diff(y_range)],...
                  'EdgeColor', 'none',...
                  'FaceColor', 'c', 'HitTest', 'off');
        hold on;
        plot(trace, 'k', 'HitTest', 'off');
        plot(events, trace(events), 'r.', 'HitTest', 'off');
        if ~isempty(state.threshold)
            t = state.threshold;
            plot([1 num_frames], t*[1 1], 'm--', 'HitTest', 'off');
            plot(events_auto, trace(events_auto), 'm.', 'HitTest', 'off');
        end
        hold off;
        box on;
        xlim([1 num_frames]);
        ylim(y_range);

        % Display the ZOOMED IN trace
        h_zoom = subplot(2,1,2);
        plot(trace, 'k', 'HitTest', 'off');
        hold on;
        h_dot = plot(-1,trace(1),'ro',...
            'MarkerFaceColor','r',...
            'MarkerSize',6,'HitTest','off');
        h_bar = plot(-1*[1 1], y_range, 'k--', 'HitTest', 'off');
        ylim(y_range);
        grid on;
        x_range = [state.x_anchor, state.x_anchor+state.x_range-1];
        xlim(x_range);
        
        if ~isempty(state.threshold)
            t = state.threshold;
            plot([1 num_frames], t*[1 1], 'm--', 'HitTest', 'off');
            for k = 1:length(events_auto)
                x = events_auto(k);
                if ((x_range(1)<=x)&&(x<=x_range(2)))
                    plot(x*[1 1], y_range, 'm');
                end
            end
        end
        
        for k = 1:length(events)
            x = events(k);
            if ((x_range(1)<=x)&&(x<=x_range(2)))
                plot(x*[1 1], y_range, 'r');
            end
        end
        
        % Add GUI event listeners
        set(h_global, 'ButtonDownFcn', @global_handler);
        set(h_zoom, 'ButtonDownFcn', @add_event);
        set(hf, 'WindowButtonMotionFcn', @track_cursor);
        set(hf, 'WindowScrollWheelFcn', @scroll_plot);
        
        function track_cursor(~, e)
            x = round(e.IntersectionPoint(1));
            if ((state.x_anchor<=x)&&(x<=state.x_anchor+state.x_range))
                if ((1<=x)&&(x<=num_frames))
                    set(h_dot,'XData',x,'YData',trace(x));
                    set(h_bar,'XData',x*[1 1]);
                end
            end
        end % track_cursor
        
        function scroll_plot(~, e)
            if (e.VerticalScrollCount < 0) % Scroll up
                get_prev_page();
            else
                get_next_page();
            end
        end % scroll_plot
        
    end % setup_gui

    function global_handler(~, e)
        switch e.Button
            case 1 % Left click -- Move the local viewpoint
                x = round(e.IntersectionPoint(1));
                if ((1<=x) && (x<=num_frames))
                    state.x_anchor = x - state.x_range/2;
                    draw_frame();
                else
                    fprintf('\n  Not a valid frame for this trace!\n');
                end
                
            case 3 % Right click -- Add threshold
                t = e.IntersectionPoint(2);
                state.threshold = t;
                events_auto = find_events(trace, t);
                draw_frame();
        end
    end % refocus_zoom

    function add_event(~, e)
        switch e.Button
            case 1 % Left click
                x = round(e.IntersectionPoint(1));
                if ((1<=x) && (x<=num_frames))
                    if (state.max_find)
                        switch (state.max_find_method)
                            case 'range'
                                x_range = max(1,x-5):min(x+5,num_frames);
                                tr_range = trace(x_range);
                                [~, max_ind] = max(tr_range);
                                x = x_range(max_ind);
                            case 'localmax'
                                iter = 0;
                                while (iter < 100)
                                    if x == 1
                                        delta_left = -Inf;
                                    else
                                        delta_left = trace(x-1) - trace(x);
                                    end
                                    
                                    if x == num_frames
                                        delta_right = -Inf; 
                                    else
                                        delta_right = trace(x+1) - trace(x);
                                    end
                                        
                                    if max([delta_left delta_right]) <= 0
                                        break;
                                    else
                                        if delta_left > delta_right
                                            x = x - 1;
                                        else
                                            x = x + 1;
                                        end
                                    end
                                    iter = iter + 1;
                                end
                                
                            otherwise
                                fprintf('  Unknown max-find method "%s"!\n', state.max_find_method);
                        end
                    end
                    events = [events; x];
                    draw_frame();
                else
                    fprintf('\n  Not a valid event for this trace!\n');
                end
                
            case 3 % Right click
                
        end
    end % add_event

end % detect_events_interactively

