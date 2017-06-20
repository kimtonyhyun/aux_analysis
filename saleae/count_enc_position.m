function counter = count_enc_position(saleae_file, encA_ch, encB_ch)
% Return the encoder position from a Saleae-generated log. Uses the
% simplest counting scheme where encA is interpreted as a "step" and encB
% is interpreted as the direction.
%
% Notes
%   - Assumes no header line in 'saleae_file'
%

data = csvread(saleae_file);

times = data(:,1);
num_rows = length(times);

encA = data(:,2+encA_ch);
encB = data(:,2+encB_ch);

counter = zeros(num_rows, 2); % Preallocate output
idx = 2;

for k = 2:num_rows
    if (~encA(k-1) && encA(k)) % Rising edge on encA
        prev_count = counter(idx-1,2);
        if encB(k)
            new_count = prev_count + 1;
        else
            new_count = prev_count - 1;
        end
        counter(idx,:) = [times(k) new_count];
        idx = idx + 1;
    end
end

counter = counter(1:(idx-1),:);
