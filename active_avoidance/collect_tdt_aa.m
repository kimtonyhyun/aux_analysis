stem = 'm753-0907-tdt';

slices = [2 3 4];
num_slices = length(slices);

A = zeros(512, 512, 4);
for sl = slices
    filename_in = sprintf('%s-sl%d.hdf5', stem, sl);
    M = load_movie(filename_in);
    A_sl = mean(M,3);
    A(:,:,sl) = A_sl;
end

save(stem, 'A');