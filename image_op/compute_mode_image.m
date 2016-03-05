function mode_img = compute_mode_image(M)

[height, width, num_frames] = size(M);
num_bins = max(50, num_frames / 50);

mode_img = zeros(height, width, class(M));

for j = 1:height
    if (mod(j,10) == 0)
        fprintf('%s: Processing line %d of %d...\n',...
            datestr(now), j, height);
    end
    for i = 1:width
        trace = squeeze(M(j,i,:));
        [n, bin_centers] = hist(trace, num_bins);
        [~, max_idx] = max(n);
        
        % Fit for mode
        half_width = max(10, floor(num_bins/20));
        fit_idx_lower = max(1, max_idx-half_width);
        fit_idx_upper = min(max_idx+half_width, num_bins);
                
        x = bin_centers(fit_idx_lower:fit_idx_upper);
        y = n(fit_idx_lower:fit_idx_upper);
        [p, ~, pmu] = polyfit(x, y, 2); % Fit quadratic, use polyfit centering
        
        % Fitted mode
        a = p(1)/pmu(2)^2;
        b = -2*pmu(1)*p(1)/pmu(2)^2 + p(2)/pmu(2);
        mode = -b/(2*a);
        
%         mode_img(j,i) = bin_centers(max_idx);
        mode_img(j,i) = mode;
    end
end