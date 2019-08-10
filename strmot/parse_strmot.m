% function parse_strmot(source)

source = 'strmot.csv';

% Saleae channels
encA_ch = 0;
encB_ch = 1;
behavior_clock_ch = 4;
ctx_clock_ch = 6;
str_clock_ch = 7;

% Load data
%------------------------------------------------------------
fprintf('Loading Saleae data into memory... '); tic;
data = load(source);
times = data(:,1);
num_rows = length(times);
t = toc; fprintf('Done in %.1f seconds!\n', t);


% Parse encoder position at full resolution
%------------------------------------------------------------
fprintf('Parsing encoder data... '); tic;
encA = data(:,2+encA_ch);
encB = data(:,2+encB_ch);

pos = zeros(num_rows, 2); % Preallocate output. Format: [time pos(click)]
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

t = toc; fprintf('Done in %.1f seconds!\n', t);

% Parse frame times
%------------------------------------------------------------
fprintf('Parsing clocks... ');
behavior_clock = data(:,2+behavior_clock_ch);
ctx_clock = data(:,2+ctx_clock_ch);
str_clock = data(:,2+str_clock_ch);

behavior_frame_times = zeros(num_rows, 1);
ctx_frame_times = zeros(num_rows, 1);
str_frame_times = zeros(num_rows, 1);

behavior_idx = 0;
ctx_idx = 0;
str_idx = 0;

for k = 2:length(times)
    if (~behavior_clock(k-1) && behavior_clock(k)) % Rising edge
        behavior_idx = behavior_idx + 1;
        behavior_frame_times(behavior_idx) = times(k);
    end
    
    if (~ctx_clock(k-1) && ctx_clock(k)) % Rising edge
        ctx_idx = ctx_idx + 1;
        ctx_frame_times(ctx_idx) = times(k);
    end
    
    if (~str_clock(k-1) && str_clock(k)) % Rising edge
        str_idx = str_idx + 1;
        str_frame_times(str_idx) = times(k);
    end
end
fprintf('Found %d behavior, %d ctx, %d str frames!\n',...
    behavior_idx, ctx_idx, str_idx);

behavior_frame_times = behavior_frame_times(1:behavior_idx);
ctx_frame_times = ctx_frame_times(1:ctx_idx);
str_frame_times = str_frame_times(1:str_idx);
