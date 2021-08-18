function show_trial(trial, vid)

t_lims = trial.times;
t0 = trial.start_time;
t_dlc = trial.t_dlc(:,1);

% Display limits
p_lims = trial.position([1 end],2);
a_lims = [0 180];

hfig = figure;

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
    h1 = plot_vertical_lines(t_dlc(1), p_lims, 'k-');
    hold on;
    subplot(ax2);
    yyaxis right;
    h2 = plot_vertical_lines(t_dlc(1), a_lims, 'k-');
    hold on;
    
    h_b = imagesc(axb, Mb(:,:,1));
    colormap gray;
    render_frame(1);
    
    % Set up handlers
    set(hfig, 'WindowScrollWheelFcn', @scroll_frame);
    set(ax1, 'ButtonDownFcn', @go_to_selected_frame);
    set(ax2, 'ButtonDownFcn', @go_to_selected_frame);
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
plot(t_lims, 90*[1 1], 'k--');
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

    function go_to_selected_frame(~, e)
        t = e.IntersectionPoint(1);
        
        % Find the DLC frame nearest to the selected point
        [~, k] = min(abs(t_dlc-t));
        
        render_frame(k);
    end

    function scroll_frame(~, e)
        k = get(h_b, 'UserData');
        if (e.VerticalScrollCount < 0) % Scroll up
            k = k - 1;
        else
            k = k + 1;
        end
        render_frame(k);
    end

    function render_frame(k)
        k = max(1,k); k = min(k,length(t_dlc)); % Clamp
        
        t = t_dlc(k);
        set(h1, 'XData', [t t NaN]);
        set(h2, 'XData', [t t NaN]);
        set(h_b, 'CData', Mb(:,:,k));
        set(h_b, 'UserData', k);
        title(axb, sprintf('Frame %d of %d', k, num_frames));
    end

end % show_trial