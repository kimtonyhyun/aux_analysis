function examine_pixel_stats(M)

[h, w, num_frames] = size(M);
max_proj = max(M,[],3);

subplot(2,2,[1 3]);
h_mp = imagesc(log(max_proj));
axis image;
colormap gray;
xlabel('X [px]');
ylabel('Y [px]');
title('Maximum projection');
set(h_mp, 'ButtonDownFcn', @maxproj_callback);

hold on;
h_dot = plot(1,1,'r.');
hold off;
draw_pixel_stats(1,1);

    function maxproj_callback(h, ~)
        axes_handle = get(h, 'Parent');
        pos = get(axes_handle, 'CurrentPoint');

        draw_pixel_stats(pos(1,1), pos(1,2));

    end % draw_pixel_stats

    function draw_pixel_stats(pixel_x, pixel_y)
        set(h_dot, 'XData', pixel_x, 'YData', pixel_y);
        
        pixel_x = round(pixel_x);
        pixel_x = max([1, pixel_x]);
        pixel_x = min([pixel_x, w]);
        
        pixel_y = round(pixel_y);
        pixel_y = max([1, pixel_y]);
        pixel_y = min([pixel_y, h]);

        trace = squeeze(M(pixel_y,pixel_x,:));
        
        % Compute stats
        %------------------------------------------------------------
        mu = mean(trace);
        med = median(trace);
        
        % Compute mode based on histogram
        num_bins = max(50, num_frames / 50);
        [n, bin_centers] = hist(trace, num_bins);
        [max_n, max_idx] = max(n);
%         mode = bin_centers(max_idx);
        
        % Fit for mode
        half_width = max(10, floor(num_bins/20));
        fit_idx_lower = max(1, max_idx-half_width);
        fit_idx_upper = min(max_idx+half_width, num_bins);
                
        x = bin_centers(fit_idx_lower:fit_idx_upper);
        y = n(fit_idx_lower:fit_idx_upper);
        [p, ~, pmu] = polyfit(x, y, 2); % Fit quadratic, use polyfit centering
        
        x_cont = linspace(x(1), x(end));
        y_cont = polyval(p, (x_cont-pmu(1))/pmu(2));
        
        % Fitted mode
        a = p(1)/pmu(2)^2;
        b = -2*pmu(1)*p(1)/pmu(2)^2 + p(2)/pmu(2);
        mode = -b/(2*a);
        
        % Show trace
        %------------------------------------------------------------
        subplot(2,2,2);
        plot(trace);
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
        xlim([bin_centers(1) bin_centers(end)]);
        ylim([0 max_n]);
        hold on;
        plot(mu*[1 1], [0 max_n], 'r--');
        plot(med*[1 1], [0 max_n], 'k--');
        plot(mode*[1 1], [0 max_n], 'c--');
        
        % Fit to peak of the distribution
%         plot(x_cont, y_cont, '-', 'LineWidth', 2);
        hold off;
    end

end % examine_pixel