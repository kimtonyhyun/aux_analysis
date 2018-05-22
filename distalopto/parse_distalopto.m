function [trial_frame_indices, velocity, frame_data] = parse_distalopto(source)
% Parse distalopto behavioral data from its Saleae CSV log.
% TODO: Handle dropped frames

frame_data = parse_frames(source);
num_trials = max(frame_data(:,1));

% Convert position and velocity to cm/s
cpr = 500; % clicks per rotation
R = 5.5; % cm, approximate effective radius on InnoWheel
frame_data(:,6) = 2*pi*R*frame_data(:,6)/cpr;
frame_data(:,7) = 2*pi*R*frame_data(:,7)/cpr;

trial_frame_indices = zeros(num_trials, 4);
velocity = cell(num_trials,1);

for trial_idx = 1:num_trials
    trial_frames = (frame_data(:,1)==trial_idx);
    
    start_frame = find(trial_frames, 1, 'first');
    last_frame = find(trial_frames, 1, 'last');
    
    cs_trace = frame_data(trial_frames, 3);
    cs_start_frame = find(cs_trace, 1, 'first');
    cs_end_frame = find(cs_trace, 1, 'last');
    
    cs_start_frame = start_frame + (cs_start_frame - 1);
    cs_end_frame = start_frame + (cs_end_frame - 1);
    
    us_trace = frame_data(trial_frames, 4);
    us_start_frame = find(us_trace, 1, 'first');
    if ~isempty(us_start_frame)
        us_start_frame = start_frame + (us_start_frame - 1);
    else
        % On "miss" trials, there is no US activation. For these cases, use
        % the end of the CS as the trial marker.
        us_start_frame = cs_end_frame;
    end
    
    trial_frame_indices(trial_idx,:) = ...
        [start_frame cs_start_frame us_start_frame last_frame];
    
    velocity{trial_idx} = frame_data(trial_frames, 7)';
end

% For viewing convenience, convert to table
frame_data = array2table(frame_data,...
    'VariableNames', {'Trial', 'AbsTime', 'CS', 'Lick', 'US', 'Position', 'Velocity'});

end % parse_distalopto

function frame_data = parse_frames(source)
% Output:
% - frame_data: [num_frames x 5] table where,
%   -> frame_data(k,1): Trial index associated with the k-th frame
%   -> frame_data(k,2): Absolute time at the beginning of the k-th frame
%   -> frame_data(k,3): 1 if CS was active at the k-th frame, 0 otherwise
%   -> frame_data(k,4): Number of detected licks between the (k-1) and k-th
%                       frames.
%   -> frame_data(k,5): 1 if US was activated between the (k-1) and k-th
%                       frames.
%   -> frame_data(k,6): Interpolated position (units of encoder "counts" 
%           at the beginning of the k-th frame
%   -> frame_data(k,7): Interpolated velocity (counts/sec) at the k-th
%           frame.
%

% Saleae channels
encA_ch = 0;
encB_ch = 1;
lick_ch = 2;
scope_en_ch = 3;
cs_ch = 5;
us_ch = 6;
frame_clock_ch = 7;

% Load data
%------------------------------------------------------------
fprintf('Loading Saleae data into memory... '); tic;
data = csvread(source, 1, 0); % Omit first line, assumed to be column headings
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

% Parse frame data
%------------------------------------------------------------
fprintf('Parsing frame data... '); tic;

scope_en = data(:,2+scope_en_ch);
frame_clock = data(:,2+frame_clock_ch);
cs_trace = data(:,2+cs_ch);
lick_trace = data(:,2+lick_ch);
us_trace = data(:,2+us_ch);

% Preallocate output. Format: [Trial-idx Time CS lick US]
frame_data = zeros(num_rows, 5);
frame_idx = 0;
trial_idx = 0;

% We can't directly sample the US trace at the frame clock edges, because
% the duration of the US signal is shorter than the frame clock period --
% hence we can easily miss the US pulse. Hence, we employ a flag.
us_detected = 0;

% Similarly, we employ a counter on the lickometer trace. Empirically, this
% scheme doesn't seem to be explicitly necessary at 30 Hz recordings, as
% the length of each individual lick contact appears to be longer than the
% frame period. Nevertheless, we employ the counter so that the code
% doesn't break in case of slower imaging rates.
num_licks = 0;

% Note that the use of the flag/counter for US/lick means that there will
% be 1 sample lag. Namely, if a US occurs _during_ frame N (i.e. after the
% frame clock went active) then the US will be marked as present on the
% ensuing frame N+1.

for k = 2:length(times)
    if (~scope_en(k-1) && scope_en(k)) % Rising edge on scope_enable
        trial_idx = trial_idx + 1;
        % Don't accumulate licks across trials. TODO: Store the number of
        % licks during ITI
        num_licks = 0;
    end
    
    if (~us_trace(k-1) && us_trace(k)) % Rising edge on US trace
        us_detected = 1;
    end
    
    if (~lick_trace(k-1) && lick_trace(k)) % Rising edge on lick trace
        num_licks = num_licks + 1;
    end
    
    if (~frame_clock(k-1) && frame_clock(k)) % Rising edge on frame clock
        frame_idx = frame_idx + 1;
        frame_data(frame_idx,:) = [trial_idx times(k) cs_trace(k) num_licks us_detected];
        num_licks = 0;
        us_detected = 0;
    end
end

frame_data = frame_data(1:frame_idx,:);

% Interpolate position and velocity at the frame clock
%------------------------------------------------------------
frame_times = frame_data(:,2);
pos_interp = interp1(pos(:,1), pos(:,2), frame_times);

dt = 0.1; % seconds, used for velocity estimation
pos2 = interp1(pos(:,1), pos(:,2), frame_times+dt/2);
pos1 = interp1(pos(:,1), pos(:,2), frame_times-dt/2);
vel = (pos2-pos1)/dt;

frame_data = [frame_data pos_interp vel];

t = toc; fprintf('Done in %.1f seconds!\n', t);
end % parse_frames