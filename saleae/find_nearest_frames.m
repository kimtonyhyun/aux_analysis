function inds2 = find_nearest_frames(frame_times1, inds1, frame_times2)
% Match frame indices between two imaging streams. Used, for example, for
% generation of side-by-side movies.

num_inds1 = length(inds1);

inds2 = zeros(1, num_inds1);
for k = 1:num_inds1
    ind1 = inds1(k);
    frame_time1 = frame_times1(ind1);
    ind2 = find(frame_times2 > frame_time1, 1, 'first');
    inds2(k) = ind2;
end