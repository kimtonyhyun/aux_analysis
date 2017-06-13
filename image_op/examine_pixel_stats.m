function examine_pixel_stats(M, varargin)

use_outline = 0;
for k = 1:length(varargin)
    vararg = varargin{k};
    if ischar(vararg)
        switch lower(vararg)
            case 'boundary'
                use_outline = 1;
                ds = varargin{k+1};
        end
    end
end

[h, w, num_frames] = size(M);
% max_proj = max(M,[],3);

% Generate clickable maximum projection image
subplot(2,2,[1 3]);
% h_mp = imagesc(log(max_proj));
h_mp = imagesc(mean(M,3));
axis image;
colormap gray;
xlabel('X [px]');
ylabel('Y [px]');
title('Mean projection image');
set(h_mp, 'ButtonDownFcn', @click_maxproj_cb);

hold on;
if use_outline
    plot_boundaries_with_transform(ds, 'g', 1, [], []);
end
h_dot = plot(1,1,'r.');
hold off;
draw_pixel_stats(1,1);

    function click_maxproj_cb(h, ~)
        axes_handle = get(h, 'Parent');
        pos = get(axes_handle, 'CurrentPoint');

        draw_pixel_stats(pos(1,1), pos(1,2));

    end % draw_pixel_stats

    function draw_pixel_stats(pixel_x, pixel_y)
        
        pixel_x = round(pixel_x);
        pixel_x = max([1, pixel_x]);
        pixel_x = min([pixel_x, w]);
        
        pixel_y = round(pixel_y);
        pixel_y = max([1, pixel_y]);
        pixel_y = min([pixel_y, h]);

        set(h_dot, 'XData', pixel_x, 'YData', pixel_y);
        
        trace = squeeze(M(pixel_y,pixel_x,:));
        
        % Compute stats
        %------------------------------------------------------------
        mu = mean(trace);
        med = median(trace);
        sig = std(trace);
        
        % Empirical histogram
        num_bins = max(100, num_frames / 50);
        [n, bin_centers] = hist(trace, num_bins);
        mode = compute_trace_mode(trace, num_bins);
        max_n = max(n);

        % Show trace
        %------------------------------------------------------------
        subplot(2,2,2);
        plot(trace);
        xlabel('Frame index');
        ylabel('Pixel value');
        xlim([1 num_frames]);
        title(sprintf('X=%d, Y=%d', pixel_x, pixel_y));
        hold on;
        plot([1 num_frames], mu*[1 1], 'r--');
        plot([1 num_frames], med*[1 1], 'k--');
        plot([1 num_frames], mode*[1 1], 'c--');
        hold off;
        
        % Show histogram
        %------------------------------------------------------------
        subplot(2,2,4);
        plot(bin_centers, n, '.-');
        xlabel('Pixel value');
        ylabel('Frequency');
        xlim([bin_centers(1) bin_centers(end)]);
        ylim([0 max_n]);
        hold on;
        plot(mu*[1 1], [0 max_n], 'r--');
        plot(med*[1 1], [0 max_n], 'k--');
        plot(mode*[1 1], [0 max_n], 'c--');
        legend(sprintf('Data (\\sigma=%.3f)', sig),...
               sprintf('Mean=%.3f', mu),...
               sprintf('Median=%.3f', med),...
               sprintf('Mode=%.3f', mode),...
               'Location', 'NorthEast');
        hold off;
    end

end % examine_pixel