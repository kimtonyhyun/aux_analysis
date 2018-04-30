function [perf, info] = decode_end(alg, ds, positions, trials, fill_type, num_runs)

args.alg_name = alg.name;
args.positions = positions;
args.trials = trials;
args.fill_type = fill_type;
args.num_runs = num_runs;

num_pos = length(positions);
pos_frames = zeros(ds.num_trials, num_pos);

target = {ds.trials.end};

train_frac = 0.7;
train_error = zeros(num_pos,2); % Format: [mean std]
test_error = zeros(num_pos,2);

for k = 1:num_pos
%     fprintf('%s: Evaluating pos=%.1f...\n', datestr(now), pos(k));
    
    [X, ks, ~, frames] = ds_dataset(ds,...
        'selection', positions(k),...
        'filling', fill_type,...
        'trials', trials,...
        'target', target);
    
    pos_frames(:,k) = frames;
    
    [tr, te, models, fit_info] = evaluate_alg(alg, X, strcmp(ks, 'north'),...
        'train_frac', train_frac,...
        'par_loops', num_runs,...
        'retain_models', true,...
        'retain_fitinfo', true);
    
    train_error(k,:) = [mean(tr) std(tr)];
    test_error(k,:) = [mean(te) std(te)];
end

perf.test_error = test_error;
perf.train_error = train_error;

% Baseline error by guessing one outcome
north_end_trials = strcmp(target(trials), 'north');
north_frac = sum(north_end_trials)/sum(trials);

perf.baseline_error = min(north_frac, 1-north_frac);

% Additional info associated with run
info.args = args;
info.models = models;
info.fit = fit_info;
info.pos_frames = pos_frames;