stem = 'f761-1019-tdt';

slices = [1 2 3];
num_slices = length(slices);

A = zeros(512, 512, 4);
for sl = slices
    filename_in = sprintf('%s-sl%d_mc2.hdf5', stem, sl);
    M = load_movie(filename_in);
    A_sl = mean(M,3);
    A(:,:,sl) = A_sl;
end

save(stem, 'A');