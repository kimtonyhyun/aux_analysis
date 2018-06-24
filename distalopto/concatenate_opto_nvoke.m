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
total_kept_frames = sum(xml_frames(:,1),1);
total_dropped_frames = sum(xml_frames(:,2),1);
fprintf('==>  Total frame count is %d; additional dropped frame count is %d\n',...
    total_kept_frames, total_dropped_frames);

%%
M = zeros(540, 720, total_kept_frames + total_dropped_frames, 'uint16'); % Preallocate

num_frames_saved = 0;
for k = 1:num_recordings
    name = recordings(k).name;
    fprintf('%s: Reading "%s" (%d of %d)\n', datestr(now), name, k, num_recordings);
    M_trial = h5read(fullfile(name,[name '.hdf5']), '/images');
    
    % Take transpose
    M_trial = permute(M_trial, [2 1 3]);

    % Handle dropped frames, if they exist
    if (xml_frames(k,2) > 0)
        xml_filename = fullfile(name, [name, '.xml']);
        xml_struct = parse_miniscope_xml(xml_filename);
        
        dropped_frames = str2num(xml_struct.dropped); %#ok<ST2NM>
        
        % Each missing frame slot will be replaced with the PREVIOUS
        % recorded frame. Except when the first frames of a recording are
        % dropped; in that case we replace with the SUBSEQUENT recorded
        % frame.
        num_corr_frames = sum(xml_frames(k,:));
        M_corr = zeros(540, 720, num_corr_frames, 'uint16');
        
        src_idx = 0;
        for m = 1:num_corr_frames
            if ismember(m, dropped_frames)
                M_corr(:,:,m) = M_trial(:,:,max(1,src_idx));
            else
                src_idx = src_idx + 1;
                M_corr(:,:,m) = M_trial(:,:,src_idx);
            end
        end
        
        fprintf('  Corrected %d dropped frames in Trial %d!\n', xml_frames(k,2), k);
        M_trial = M_corr;
    end
    
    % Save to data
    num_frames_in_trial = size(M_trial,3);
    idx1 = num_frames_saved + 1;
    idx2 = num_frames_saved + num_frames_in_trial;
    M(:,:,idx1:idx2) = M_trial;
    
    num_frames_saved = num_frames_saved + num_frames_in_trial;
end

fprintf('%s: Done!\n', datestr(now));

%%

F = compute_fluorescence_stats(M);
plot(F);
grid on;
xlim([1 size(M,3)]);
xlabel('Frames');
ylabel('Fluorescence');
