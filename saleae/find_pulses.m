function pulses = find_pulses(saleae_file, channel)
% Returns the rise and fall times of all positive pulses on Saleae log.
% Note that pulses are recorded only if BOTH the positive edge and the
% negative edges are captured in the file.

data = csvread(saleae_file);
times = data(:,1);
trace = data(:,2+channel);

pulses = zeros(length(times), 2); % Preallocate
num_pulses = 0;

pulse_detected = 0;
prev_val = trace(1);
for k = 2:length(trace)
    val = trace(k);
    
    if (~pulse_detected)
        % Look for positive edge
        if (~prev_val && val) % Rising edge
            pulse_detected = 1;
            pulse_rise_time = times(k);
        end
    else
        % Look for negative edge
        if (prev_val && ~val) % Negative edge
            pulse_fall_time = times(k);
            
            num_pulses = num_pulses + 1;
            pulses(num_pulses,:) = [pulse_rise_time, pulse_fall_time];
            
            pulse_detected = 0;
        end
    end
    prev_val = val;
end

pulses = pulses(1:num_pulses,:);