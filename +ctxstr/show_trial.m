function h = show_trial(trial, vid, h)
% Tool for visualizing the behavior video alongside extracted behavioral
% data (i.e. encoder velocity and position; front and hind limb angles).
%
% "Selected time" t0 can be accessed via 'h.UserData.t0'.
%
% Notes:
%   - Behavioral video ('vid') may be provided as a VideoReader object or
%       as video data preloaded into memory (ctxstr.load_behavior_movie).
%   - Click on the behavioral video image to start/stop playback.
%   - Right click on left panels to set "selected time".

t_lims = trial.times; % Note: Includes padding
t_dlc = trial.dlc.t(:,1);

% Display limits
p_lims = trial.position([1 end],2);
a_lims = [0 180];

if exist('h', 'var')
    figure(h);
    clf;
else
    h = figure;
end
h.UserData.t0 = []; % "Selected time"

% GUI setup
%------------------------------------------------------------
selected_frame = [];
playback_active = false;

color1 = [0 0.4470 0.7410]; % Default blue
color2 = [0.85 0.325 0.098]; % Default orange/red

% Custom "subplot" command that leaves less unusued space between panels
sp = @(m,n,p) subtightplot(m, n, p, 0.05, 0.05, 0.05); % Gap, Margin-X, Margin-Y

ax1 = sp(2,2,1);
ax2 = sp(2,2,3);
axb = sp(2,2,[2 4]);

% Load behavioral movie for the trial
if iscell(vid) % Videos have been pre-loaded into memory
    Mb = vid{trial.ind};
else % Assume VideoReader object
    Mb = load_behavior_movie_frames(vid, trial.dlc.t(1,2), trial.dlc.t(end,2));
end
num_frames = size(Mb, 3);

% Set up interactive elements
subplot(ax1);
yyaxis right;
h1_t0 = plot_vertical_lines(0, p_lims, 'k--', 'HitTest', 'off');
hold on;
h1_t = plot_vertical_lines(0, p_lims, 'k-', 'HitTest', 'off');

subplot(ax2);
h2_t0 = plot_vertical_lines(0, a_lims, 'k--', 'HitTest', 'off');
hold on;
h2_t = plot_vertical_lines(0, a_lims, 'k-', 'HitTest', 'off');

subplot(axb);
h_b = imagesc(Mb(:,:,1), [0 200]);
% set(axb, 'XTick', []);
% set(axb, 'YTick', []);
axis image; colormap gray;

set_t0(1);
render_frame(1);

% Set up handlers
set(h, 'WindowScrollWheelFcn', @scroll_frame);
set(ax1, 'ButtonDownFcn', @click_handler);
set(ax2, 'ButtonDownFcn', @click_handler);
set(h_b, 'ButtonDownFcn', @playback_handler);

% Plot velocity and position
%------------------------------------------------------------
subplot(ax1);
yyaxis left;
v_lims = tight_plot(trial.velocity(:,1), trial.velocity(:,2), 'Color', color1, 'HitTest', 'off');
v_lims(1) = min([-5 v_lims(1)]);
ylim(v_lims);
plot(t_lims, [0 0], ':', 'Color', color1);
ylabel('Velocity (cm/s)');
yyaxis right;
plot(trial.position(:,1), trial.position(:,2), 'HitTest', 'off');
ylim(p_lims);
ylabel('Position (encoder count)');
plot_rectangles(trial.opto, p_lims);
plot_vertical_lines(trial.motion.onsets, p_lims, 'r-', 'HitTest', 'off');
plot_vertical_lines([trial.start_time trial.us_time], p_lims, 'b:', 'HitTest', 'off');
plot(trial.lick_times, 0.95*p_lims(2)*ones(size(trial.lick_times)), 'b.', 'HitTest', 'off');
set(ax1, 'TickLength', [0 0]);
title(sprintf('Trial %d', trial.ind));
xlim(t_lims);

% Plot front and hind limb angles
%------------------------------------------------------------
subplot(ax2);
plot(t_dlc, trial.dlc.beta_f, 'Color', color1, 'HitTest', 'off');
plot(t_dlc, trial.dlc.beta_h, 'Color', color2, 'HitTest', 'off');
plot_rectangles(trial.opto, a_lims);
plot(t_lims, 90*[1 1], 'k:', 'HitTest', 'off');
plot_vertical_lines(trial.motion.onsets, p_lims, 'r-', 'HitTest', 'off');
plot_vertical_lines([trial.start_time trial.us_time], a_lims, 'b:', 'HitTest', 'off');
plot(trial.lick_times, 0.95*a_lims(2)*ones(size(trial.lick_times)), 'b.', 'HitTest', 'off');
ylim(a_lims);
set(ax2, 'YTick', 0:45:180);
set(ax2, 'TickLength', [0 0]);
ylabel('Limb angle (\circ); Front=blue, Hind=red');
xlabel('Time (s)');
xlim(t_lims);

    function click_handler(~, e)
        t = e.IntersectionPoint(1);
        
        % Find the DLC frame nearest to the selected point
        [~, k] = min(abs(t_dlc-t));
        
        
        switch e.Button
            case 1 % Left click
                render_frame(k);
                playback_active = false;
                
            case 3 % Right click - Set 'selected frame'
                set_t0(k);
                render_frame(k);
                playback_active = false;
        end
    end

    function playback_handler(~, ~)
        if playback_active
            playback_active = false;
        else
            [~, k1] = min(abs(t_dlc - h.UserData.t0));
            playback_active = true;
            for k = k1:num_frames
                if playback_active
                    render_frame(k);
                else
                    break;
                end
            end
            playback_active = false;
        end
    end

    function scroll_frame(~, e)
        k = selected_frame;
        if (e.VerticalScrollCount < 0) % Scroll up
            k = k - 1;
        else
            k = k + 1;
        end
        set_t0(k);
        render_frame(k);
    end

    function render_frame(k)
        k = max(1,k); k = min(k,num_frames); % Clamp
        
        t = t_dlc(k);
        set(h1_t, 'XData', [t t NaN]);
        set(h2_t, 'XData', [t t NaN]);
        set(h_b, 'CData', Mb(:,:,k));
        title(axb, sprintf('Frame %d of %d; Time = %.3f s', k, num_frames, t));
        
        drawnow;
    end

    function set_t0(k)
        t = t_dlc(k);
        
        h.UserData.t0 = t;
        selected_frame = k;
        set(h1_t0, 'XData', [t t NaN]);
        set(h2_t0, 'XData', [t t NaN]);
    end

end % show_trial