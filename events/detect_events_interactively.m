function events = detect_events_interactively(trace)

% Basic trace properties
num_frames = length(trace);
M = max(trace);
m = min(trace);
y_range = [m M] + 0.1*(M-m)*[-1 1];

% Set up GUI
zoom_factor = 0.5;
paging_factor = 0.75;
init_range = min(2500, num_frames)-1;

state.x_anchor = 1;
state.x_range = init_range;

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

            otherwise
                fprintf('  Sorry, could not parse "%s"\n', resp);
        end
    end
        
    resp = lower(strtrim(input(prompt, 's')));
    val = str2double(resp);
end % Main interaction loop

    function get_next_page()
        new_anchor = state.x_anchor + paging_factor*state.x_range + 1;
        if (new_anchor < num_frames)
            state.x_anchor = new_anchor;
            draw_frame();
        else
            fprintf('  Already at end of trace!\n');
        end
    end % get_next_page

    function get_prev_page()
        new_anchor = state.x_anchor - (paging_factor*state.x_range + 1);
        state.x_anchor = max(1, new_anchor);
        draw_frame();
    end % get_prev_page

    function draw_frame()
        clf;

        % Display the GLOBAL trace
        subplot(2,1,1);
        rectangle('Position',[state.x_anchor y_range(1) state.x_range diff(y_range)],...
                  'EdgeColor', 'none',...
                  'FaceColor', 'c');
        hold on;
        plot(trace, 'k');
        plot(events, trace(events), 'r.');
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
        x_range = [state.x_anchor, state.x_anchor+state.x_range];
        xlim(x_range);
        hold on;
        for k = 1:length(events)
            x = events(k);
            if ((x_range(1)<=x)&&(x<=x_range(2)))
                plot(x*[1 1], y_range, 'r');
            end
        end
        
        % Add GUI event listeners
        set(h_zoom, 'ButtonDownFcn', @add_event);
        set(hf, 'WindowButtonMotionFcn', @track_cursor);
        
        function track_cursor(~, e)
            x = round(e.IntersectionPoint(1));
            if ((state.x_anchor<=x)&&(x<=state.x_anchor+state.x_range))
                if ((1<=x)&&(x<=num_frames))
                    set(h_dot,'XData',x,'YData',trace(x));
                    set(h_bar,'XData',x*[1 1]);
                end
            end
        end % track_cursor
        
    end % setup_gui

    function add_event(~, e)
        switch e.Button
            case 1 % Left click
                x = round(e.IntersectionPoint(1));
                if ((1<=x) && (x<=num_frames))
                    events = [events; x];
                    draw_frame();
                else
                    fprintf('\n  Not a valid event for this trace!\n');
                end
                
            case 3 % Right click
                
        end
    end % add_event

end % detect_events_interactively

