function [test_error, train_error, baseline_error] = decode_end(alg, ds, positions, trials, fill_type, num_runs)

num_pos = length(positions);
target = {ds.trials.end};

train_error = zeros(num_pos,2); % Format: [mean std]
test_error = zeros(num_pos,2);

for k = 1:num_pos
%     fprintf('%s: Evaluating pos=%.1f...\n', datestr(now), pos(k));
    
    [X, ks] = ds_dataset(ds,...
        'selection', positions(k),...
        'filling', fill_type,...
        'trials', trials,...
        'target', target);
    
    [tr, te] = evaluate_alg(alg, X, strcmp(ks, 'north'),...
        'train_frac', 0.7,...
        'par_loops', num_runs);
    
    train_error(k,:) = [mean(tr) std(tr)];
    test_error(k,:) = [mean(te) std(te)];
end

% Baseline error by guessing one outcome
north_end_trials = strcmp(target(trials), 'north');
north_frac = sum(north_end_trials)/sum(trials);

baseline_error = min(north_frac, 1-north_frac);