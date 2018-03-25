stem = 'm756-1022';

slices = [1 2 3];
num_slices = length(slices);

for sl = slices
    filename_in = sprintf('%s-sl%d.hdf5', stem, sl);
    filename_mc1 = sprintf('%s-sl%d_mc1.hdf5', stem, sl);
    filename_mc2 = sprintf('%s-sl%d_mc2.hdf5', stem, sl);
    
    % Round 1 of TurboReg
    M = load_movie(filename_in);
    A = mean(M,3);
    clear M;
    register_movie(filename_in, filename_mc1, 'nofilter', 'noroi', 'ref', A);
    
    M = load_movie(filename_mc1);
    A = mean(M,3);
    clear M;
    register_movie(filename_mc1, filename_mc2, 'nofilter', 'noroi', 'ref', A);
end