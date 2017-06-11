clear info filters traces;

info.type = 'cnmf';
info.movie_source = movie_source;
info.cnmf.options = options;

traces = C';
info.num_pairs = size(traces,2);
filters = reshape(full(A), d1, d2, info.num_pairs);

info.cnmf.b = b;
info.cnmf.f = f;
info.cnmf.P = P;

timestamp = datestr(now, 'yymmdd-HHMMSS');
rec_savename = sprintf('rec_%s.mat', timestamp);
save(rec_savename, 'info', 'filters', 'traces', '-v7.3');