function frame_indices = generate_pmtext_reachbot(bd)
% Converts reaching bot behavioral data into PlusMaze text format.
%

num_frames = length(bd.b);

% Format: [Motion-start Turn-onset Motion-end Reward]
frame_indices = zeros(500,4); % Preallocate

idx = 0;
for k = 1:num_frames
    switch bd.b(k)
        case 1 % Motion start
            idx = idx + 1;
            frame_indices(idx,1) = k;
            
        case 2 % Turn onset
            if idx > 0
                frame_indices(idx,2) = k;
            end
            
        case 3 % Motion end
            if idx > 0
                frame_indices(idx,3) = k;
            end
            
        case 4 % Reward
            if idx > 0
                frame_indices(idx,4) = k;
            end
    end
end
frame_indices = frame_indices(1:idx,:);

% % Generate text file
% %------------------------------------------------------------
% outname = sprintf('reach_%s.txt', bd.day);
% fid = fopen(outname, 'w');
% 
% num_trials = size(frame_indices,1);
% pm_filler = 'east north north 10.0';
% 
% first_frame = frame_indices(1,1);
% if (first_frame ~= 1)
%     fprintf(fid, '%s 1 1 1 %d\n', pm_filler, first_frame-1);
% end
% 
% for k = 1:num_trials
%     fprintf(fid, '%s %d %d %d %d\n', pm_filler,...
%         frame_indices(k,1), frame_indices(k,2), frame_indices(k,3), frame_indices(k,4));
% end
% 
% last_frame = frame_indices(end,4);
% if (last_frame ~= num_frames)
%     fprintf(fid, '%s %d %d %d %d\n', pm_filler,...
%         last_frame+1, last_frame+1, last_frame+1, num_frames);
% end
% 
% fclose(fid);
