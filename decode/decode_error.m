function [test_error, train_error, info] = decode_error(alg, ds, positions, trials, fill_type, num_runs)

num_pos = length(positions);

% Target: 1 if trial incorrect, 0 otherwise
target = cellfun(@not, {ds.trials.correct}, 'UniformOutput', false);

train_error = zeros(num_pos,2); % Format: [mean std]
test_error = zeros(num_pos,2);

for k = 1:num_pos
%     fprintf('%s: Evaluating pos=%.1f...\n', datestr(now), pos(k));
    
    [X, ks] = ds_dataset(ds,...
        'selection', positions(k),...
        'filling', fill_type,...
        'trials', trials,...
        'target', target);
    
    [tr, te] = evaluate_alg(alg, X, cell2mat(ks),...
        'train_frac', 0.7,...
        'par_loops', num_runs);
    
    train_error(k,:) = [mean(tr) std(tr)];
    test_error(k,:) = [mean(te) std(te)];
end

% Baseline error by guessing one outcome
target = cell2mat(target);
incorrect_trials = target(trials);
incorrect_frac = sum(incorrect_trials)/sum(trials);

info.num_trials = sum(trials);
info.baseline_error = min(incorrect_frac, 1-incorrect_frac);