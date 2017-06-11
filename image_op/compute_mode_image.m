function mode_img = compute_mode_image(M, num_bins)

[height, width, ~] = size(M);
mode_img = zeros(height, width, 'like', M);

for j = 1:height
    if (mod(j,25) == 0)
        fprintf('%s: Processing line %d of %d...\n',...
            datestr(now), j, height);
    end
    parfor i = 1:width
        trace = squeeze(M(j,i,:));
        mode_img(j,i) = compute_trace_mode(trace, num_bins);
    end
end