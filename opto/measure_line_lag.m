%% Load synchronization data

% Format:
%   Ch0: Master frame clock
%   Ch1: Master line clock
%   Ch4: Slave frame clock
%   Ch5: Slave line clock
% Note: We need to offset 2 for: Matlab 1-indexing, and Time column
master_frame_clock_col = 2 + 0; % Ch0
master_line_clock_col = 2 + 1;
slave_frame_clock_col = 2 + 2;
slave_line_clock_col = 2 + 3;

sync_source = 'lines.csv';
sync = csvread(sync_source, 1, 0); % Skip first line (header)
num_rows = size(sync, 1);

%% Read through data

% Preallocate scratch pad
% Format: [master_frame_count slave_frame_count slave_line_lag]
lag = zeros(num_rows, 3);

% Note: In ScanImage, the line clock actually slightly leads
%   the frame clock!
master_frame_counter = 1;
slave_frame_counter = 1;

master_line_counter = 0;
slave_line_counter = 0;

prev_master_frame_clk = sync(1, master_frame_clock_col);
prev_master_line_clk = sync(1, master_line_clock_col);
prev_slave_frame_clk = sync(1, slave_frame_clock_col);
prev_slave_line_clk = sync(1, slave_line_clock_col);

for k = 2:num_rows
    % Read current values
    master_frame_clk = sync(k, master_frame_clock_col);
    master_line_clk = sync(k, master_line_clock_col);
    slave_frame_clk = sync(k, slave_frame_clock_col);
    slave_line_clk = sync(k, slave_line_clock_col);
    
    % Falling master frame clock
    if (prev_master_frame_clk && ~master_frame_clk)
        master_line_counter = 0;
        master_frame_counter = master_frame_counter + 1;
    end
    
    % Falling slave frame clock
    if (prev_slave_frame_clk && ~slave_frame_clk)
        slave_line_counter = 0;
        slave_frame_counter = slave_frame_counter + 1;
    end
    
    % Rising master line clock
    if (~prev_master_line_clk && master_line_clk)
        master_line_counter = master_line_counter + 1;
    end
    
    % Rising slave line clock
    if (~prev_slave_line_clk && slave_line_clk)
        slave_line_counter = slave_line_counter + 1;
        
        % For the first line of the frame, measure the lag
        if (slave_line_counter == 1)
            line_lag = master_line_counter - slave_line_counter;
            lag(slave_frame_counter,:) = ...
                [master_frame_counter slave_frame_counter line_lag];
        end
    end
    
    % Set prev values
    prev_master_frame_clk = master_frame_clk;
    prev_master_line_clk = master_line_clk;
    prev_slave_frame_clk = slave_frame_clk;
    prev_slave_line_clk = slave_line_clk;
end

lag = lag(1:slave_frame_counter-1,:);