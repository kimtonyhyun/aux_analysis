function pos = parse_encoder(saleae_file, encA_ch, encB_ch)
% Output:
%   pos(:,1): Times at which encoder value changed
%   pos(:,2): Accumulated encoder count

if isstring(saleae_file)
    data = csvread(saleae_file);
else
    data = saleae_file;
end

times = data(:,1);
num_rows = length(times);
encA = data(:,2+encA_ch);
encB = data(:,2+encB_ch);

pos = zeros(num_rows, 2); % Preallocate
idx = 0;
curr_pos = 0;
for k = 2:num_rows
    if (~encA(k-1) && encA(k)) % Rising edge on encA
        if encB(k)
            curr_pos = curr_pos + 1;
        else
            curr_pos = curr_pos - 1;
        end
        idx = idx + 1;
        pos(idx,:) = [times(k) curr_pos];
    end
end
pos = pos(1:idx,:);
