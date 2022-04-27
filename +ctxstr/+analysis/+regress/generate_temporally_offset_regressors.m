function X = generate_temporally_offset_regressors(regressor, num_pre, num_post)

num_samples = length(regressor);
X = zeros(num_pre+1+num_post, num_samples);

ind = 1;
for k = fliplr(1:num_pre)
    X(ind,1:end-k) = regressor(1+k:end);
    ind = ind + 1;
end

X(ind,:) = regressor;
ind = ind + 1;

for k = 1:num_post
    X(ind,1+k:end) = regressor(1:end-k);
    ind = ind + 1;
end