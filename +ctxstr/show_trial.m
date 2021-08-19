function show_trial(trial, vid)

t_lims = trial.times;
t0 = trial.start_time;
t_dlc = trial.t_dlc(:,1);

% Display limits
p_lims = trial.position([1 end],2);
a_lims = [0 180];

hfig = figure;

playback_active = false;
state.t1 = t_dlc(1);
state.curr_frame = [];

if ~exist('vid', 'var')
    ax1 = subplot(2,1,1);
    ax2 = subplot(2,1,2);
else
    ax1 = subplot(2,2,1);
    ax2 = subplot(2,2,3);
    axb = subplot(2,2,[2 4]);
    
    % Load behavioral movie for the trial
    %------------------------------------------------------------
    frames_to_load = trial.t_dlc([1 end],2);
    num_frames = diff(frames_to_load) + 1;
    tic;
    fprintf('Loading frames %d-%d (%d total) for Trial %d... ',...
        frames_to_load(1), frames_to_load(2), num_frames, trial.ind);
    Mb = vid.read(frames_to_load);
    Mb = squeeze(Mb(:,:,1,:)); % Data is grayscale
    t_load = toc;
    fprintf('Done! (%.1f s; %.1f ms/frame)\n',...
        t_load, t_load/num_frames*1e3);
       
    % Set up interactive elements
    subplot(ax1);
    yyaxis right;
    h_time_origin1 = plot_vertical_lines(state.t1, p_lims, 'k:', 'HitTest', 'off');
    hold on;
    h_time_current1 = plot_vertical_lines(state.t1, p_lims, 'k-', 'HitTest', 'off');
    
    subplot(ax2);
    yyaxis right;
    h_time_origin2 = plot_vertical_lines(state.t1, a_lims, 'k:', 'HitTest', 'off');
    hold on;
    h_time_current2 = plot_vertical_lines(state.t1, a_lims, 'k-', 'HitTest', 'off');
    
    subplot(axb);
    h_b = imagesc(Mb(:,:,1), [0 255]);
    axis image; colormap gray;
    render_frame(1);
    
    % Set up handlers
    set(hfig, 'WindowScrollWheelFcn', @scroll_frame);
    set(ax1, 'ButtonDownFcn', @click_handler);
    set(ax2, 'ButtonDownFcn', @click_handler);
    set(h_b, 'ButtonDownFcn', @playback_handler);
end

subplot(ax1);
yyaxis left;
tight_plot(trial.velocity(:,1), trial.velocity(:,2), 'HitTest', 'off');
ylabel('Velocity (cm/s)');
yyaxis right;
plot(trial.position(:,1), trial.position(:,2), 'HitTest', 'off');

ylim(p_lims);
ylabel('Position (encoder count)');
hold on;
plot_rectangles(trial.opto, p_lims);
plot_vertical_lines(trial.movement_onset_time, p_lims, 'r:', 'HitTest', 'off');
plot_vertical_lines([t0 trial.us_time], p_lims, 'b:', 'HitTest', 'off');
hold off;
set(ax1, 'TickLength', [0 0]);
title(sprintf('Trial %d', trial.ind));
xlim(t_lims);

subplot(ax2);
yyaxis left;
plot(t_dlc, trial.beta_f, 'HitTest', 'off');
ylim(a_lims);
ylabel('Front limb angle (\circ)');
yyaxis right;
plot(t_dlc, trial.beta_h, 'HitTest', 'off');
hold on;
plot_rectangles(trial.opto, a_lims);
plot(t_lims, 90*[1 1], 'k--', 'HitTest', 'off');
plot_vertical_lines(trial.movement_onset_time, a_lims, 'r:', 'HitTest', 'off');
plot_vertical_lines([t0 trial.us_time], a_lims, 'b:', 'HitTest', 'off');
plot(trial.lick_times, 175*ones(size(trial.lick_times)), 'b.', 'HitTest', 'off');
hold off;
ylim(a_lims);
set(ax2, 'YTick', 0:45:180);
set(ax2, 'TickLength', [0 0]);
ylabel('Hind limb angle (\circ)');
xlabel('Time (s)');
xlim(t_lims);

    function click_handler(~, e)
        t = e.IntersectionPoint(1);
        
        % Find the DLC frame nearest to the selected point
        [~, k] = min(abs(t_dlc-t));
        t = t_dlc(k);
        
        switch e.Button
            case 1 % Left click
                state.t1 = t;
                set(h_time_origin1, 'XData', [t t NaN]);
                set(h_time_origin2, 'XData', [t t NaN]);
                
                render_frame(k);
                playback_active = false;
                
            case 3 % Right click
                fprintf('  Not implemented\n');
        end
    end

    function playback_handler(~, ~)
        if playback_active
            playback_active = false;
        else
            [~, k1] = min(abs(t_dlc-state.t1));
            playback_active = true;
            for k = k1:num_frames
                if playback_active
                    render_frame(k);
                else
                    break;
                end
            end
        end
    end

    function scroll_frame(~, e)
        k = state.curr_frame;
        if (e.VerticalScrollCount < 0) % Scroll up
            k = k - 1;
        else
            k = k + 1;
        end
        render_frame(k);
    end

    function render_frame(k)
        k = max(1,k); k = min(k,num_frames); % Clamp
        
        t = t_dlc(k);
        set(h_time_current1, 'XData', [t t NaN]);
        set(h_time_current2, 'XData', [t t NaN]);
        set(h_b, 'CData', Mb(:,:,k));
        title(axb, sprintf('Frame %d of %d', k, num_frames));
        drawnow;
        
        state.curr_frame = k;
    end

end % show_trial