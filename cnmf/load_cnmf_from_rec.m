function [A,C,b,f,P,options] = load_cnmf_from_rec(rec_dir)

source = get_most_recent_file(rec_dir, 'rec_*.mat');
rec = load(source);

b = rec.info.cnmf.b;
f = rec.info.cnmf.f;
P = rec.info.cnmf.P;
options = rec.info.cnmf.options;

num_pixels = options.d1 * options.d2;
K = rec.info.num_pairs;

A = sparse(double(reshape(rec.filters, [num_pixels, K])));
C = rec.traces';