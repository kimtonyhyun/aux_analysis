function [laser_off, laser_on, frame_times] = compute_laser_on_frames(saleae_file, frame_clk_col, opto_en_col)
% Compute a list of laser-on frames based on Saleae export

data = csvread(saleae_file);
time = data(:,1);
frame_clk = data(:,2+frame_clk_col);
opto_en = data(:,2+opto_en_col);

laser_on = zeros(1,length(frame_clk)); % Preallocate
frame_times = zeros(size(laser_on));

frame_count = 0;
laser_on_count = 0;

prev_val = frame_clk(1);
for k = 2:length(frame_clk)
    val = frame_clk(k);
    if (~prev_val && val) % Rising edge on frame clk
        frame_count = frame_count + 1;
        frame_times(frame_count) = time(k);

        if opto_en(k)
            laser_on_count = laser_on_count + 1;
            laser_on(laser_on_count) = frame_count;
        end
    end
    prev_val = val;
end

frame_times = frame_times(1:frame_count);
laser_on = laser_on(1:laser_on_count);
laser_off = setdiff(1:frame_count, laser_on);