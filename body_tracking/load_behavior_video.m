function M = load_behavior_video(behavior_source)

vid = VideoReader(behavior_source);
num_frames = vid.NumberOfFrames;
height = vid.Height;
width = vid.Width;

M = zeros(height, width, num_frames, 'uint8');

for k = 1:num_frames
    if (mod(k,1000)==0)
        fprintf('%s: Loaded %d of %d frames...\n', datestr(now), k, num_frames);
    end
    frame = vid.read(k);
    M(:,:,k) = frame(:,:,1);
end
fprintf('%s: Done!\n', datestr(now));