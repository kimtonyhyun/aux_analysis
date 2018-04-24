function [test_error, train_error, info] = decode_start(alg, ds, positions, trials, fill_type, num_runs)

num_pos = length(positions);
target = {ds.trials.start};

train_error = zeros(num_pos,2); % Format: [mean std]
test_error = zeros(num_pos,2);

for k = 1:num_pos
%     fprintf('%s: Evaluating pos=%.1f...\n', datestr(now), pos(k));
    
    [X, ks] = ds_dataset(ds,...
        'selection', positions(k),...
        'filling', fill_type,...
        'trials', trials,...
        'target', target);
    
    [tr, te] = evaluate_alg(alg, X, strcmp(ks, 'east'),...
        'train_frac', 0.7,...
        'par_loops', num_runs);
    
    train_error(k,:) = [mean(tr) std(tr)];
    test_error(k,:) = [mean(te) std(te)];
end

% Baseline error by guessing one outcome
east_end_trials = strcmp(target(trials), 'east');
east_frac = sum(east_end_trials)/sum(trials);

info.num_trials = sum(trials);
info.baseline_error = min(east_frac, 1-east_frac);