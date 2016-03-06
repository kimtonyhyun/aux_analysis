function mode_img = compute_mode_image(M)

[height, width, ~] = size(M);
mode_img = zeros(height, width, class(M));

for j = 1:height
    if (mod(j,25) == 0)
        fprintf('%s: Processing line %d of %d...\n',...
            datestr(now), j, height);
    end
    for i = 1:width
        trace = squeeze(M(j,i,:));
        mode_img(j,i) = compute_trace_mode(trace);
    end
end