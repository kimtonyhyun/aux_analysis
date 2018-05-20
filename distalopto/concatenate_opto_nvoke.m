clear;

%%

recordings = dir('recording_*');
num_recordings = length(recordings);
fprintf('Found %d recordings\n', num_recordings);

%% Count frames in XML

xml_frames = zeros(num_recordings, 2); % [Recorded-frames Dropped frames]

for k = 1:num_recordings
    name = recordings(k).name;
    xml_filename = fullfile(name, [name, '.xml']);
    xml_struct = parse_miniscope_xml(xml_filename);
    
    num_frames = str2double(xml_struct.frames);
    num_dropped_frames = str2double(xml_struct.dropped_count);
    xml_frames(k,:) = [num_frames num_dropped_frames];
    if (num_dropped_frames ~= 0)
        fprintf('Trial %d ("%s") has %d dropped frames!\n',...
            k, name, num_dropped_frames);
    end
end
total_frames = sum(xml_frames(:,1),1);
total_dropped_frames = sum(xml_frames(:,2),1);
fprintf('==>  Total frame count is %d; dropped frame count is %d\n',...
    total_frames, total_dropped_frames);

%%
M = zeros(540, 720, 30000, 'uint16'); % Preallocate

num_frames_saved = 0;
for k = 1:num_recordings
    name = recordings(k).name;
    fprintf('%s: Reading "%s" (%d of %d)\n', datestr(now), name, k, num_recordings);
    M_trial = h5read(fullfile(name,[name '.hdf5']), '/images');
    
    % Take transpose
    M_trial = permute(M_trial, [2 1 3]);
    
%     % Spatial downsample
%     M_trial = M_trial(1:2:end,1:2:end,:)+...
%               M_trial(2:2:end,1:2:end,:)+...
%               M_trial(1:2:end,2:2:end,:)+...
%               M_trial(2:2:end,2:2:end,:);
          
    % Save to data
    num_frames_in_trial = size(M_trial,3);
    idx1 = num_frames_saved + 1;
    idx2 = num_frames_saved + num_frames_in_trial;
    M(:,:,idx1:idx2) = M_trial;
    
    num_frames_saved = num_frames_saved + num_frames_in_trial;
end

M = M(:,:,1:num_frames_saved);
fprintf('%s: Done!\n', datestr(now));