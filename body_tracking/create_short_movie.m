function create_short_movie(input_filename, num_frames)
% Create a new MP4 movie, taking the first 'num_frames' frames of the
% movie `input_filename`.

% Default parameters:
frame_rate = 30;

timestamp = datestr(now, 'yymmdd-HHMMSS');
output_name = sprintf('out_%s.avi', timestamp);

input_vid = VideoReader(input_filename);

output_vid = VideoWriter(output_name, 'MPEG-4');
output_vid.Quality = 100;
output_vid.FrameRate = frame_rate;

open(output_vid);
for k = 1:num_frames
    A = input_vid.readFrame;
    writeVideo(output_vid, A);
end
close(output_vid);