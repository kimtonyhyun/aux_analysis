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

            case 'n' % Next
                new_anchor = state.x_anchor + paging_factor*state.x_range + 1;
                if (new_anchor < num_frames)
                    state.x_anchor = new_anchor;
                    draw_frame();
                else
                    fprintf('  Already at end of trace!\n');
                end

            case 'p' % Previous
                new_anchor = state.x_anchor - (paging_factor*state.x_range + 1);
                if (new_anchor + state.x_range > 0)
                    state.x_anchor = new_anchor;
                    draw_frame();
                else
                    fprintf('  Already at beginning of trace!\n');
                end

            otherwise
                fprintf('  Sorry, could not parse "%s"\n', resp);
        end
    end
        
    resp = lower(strtrim(input(prompt, 's')));
    val = str2double(resp);
end

    function draw_frame()
        clf;

        subplot(2,1,1);
        rectangle('Position',[state.x_anchor y_range(1) state.x_range diff(y_range)],...
                  'EdgeColor', 'none',...
                  'FaceColor', 'c');
        hold on;
        plot(trace, 'k');
        hold off;
        box on;
        xlim([1 num_frames]);
        ylim(y_range);

        h_zoom = subplot(2,1,2);
        plot(trace, 'k');
        ylim(y_range);
        grid on;
        xlim([state.x_anchor, state.x_anchor+state.x_range]);
        hold on;
        for k = 1:length(events)
            event = events(k);
            plot(event*[1 1], y_range, 'r');
        end
        set(h_zoom, 'ButtonDownFcn', @add_event);
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

