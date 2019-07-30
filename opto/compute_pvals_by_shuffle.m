function [stats_sig, info] = compute_pvals_by_shuffle(ds, opto_trial_inds, varargin)

% Default parameters
laser_on_type = 'real'; % e.g. 'real' or 'sham' opto trials
score_type = 'fluorescence';
p_thresh = 0.001/2; % The 2 is for two-sided correction

if ~isempty(varargin)
    for k = 1:length(varargin)
        if ischar(varargin{k})
            vararg = lower(varargin{k});
            switch vararg
                case 'laser_type'
                    laser_on_type = varargin{k+1};
                case 'score_type'
                    score_type = varargin{k+1};
                case {'p', 'p_val'}
                    p_thresh = varargin{k+1};
            end
        end
    end
end

laser_off_trials = opto_trial_inds.off;
laser_on_trials = opto_trial_inds.(laser_on_type);

num_cells = ds.num_classified_cells;
pvals = zeros(num_cells, 1);

effect_type = categorical(repmat({'-'}, num_cells, 1),...
    {'-', 'inhibited', 'disinhibited'});
mean_scores = zeros(num_cells, 2); % [Laser-off Laser-on]
distrs = zeros(num_cells, 3); % [5th-percentile median 95-th percentile]

% Run shuffle
%------------------------------------------------------------
fprintf('%s: Using laser_on_type=%s, score_type=%s, p_thresh=%.4f\n',...
    datestr(now), laser_on_type, score_type, p_thresh);
for k = 1:num_cells
    fprintf('%s: Cell %d...\n', datestr(now), k);
    
    % Perform shuffle test
    switch (score_type)
        case 'fluorescence'
            scores_k = compute_trial_mean_fluorescences(ds, k);
        case 'event_rate'
            scores_k = compute_trial_event_rates(ds, k);
    end
    
    [p1, p2, shuffle_info] = shuffle_scores(scores_k, laser_off_trials, laser_on_trials);
    
    mean_scores(k,1) = shuffle_info.true_scores.off;
    mean_scores(k,2) = shuffle_info.true_scores.on;
    distrs(k,:) = shuffle_info.shuffle_distr.y([1 3 5]);
    
    [pvals(k), type] = min([p1, p2]);
    
    if (pvals(k) < p_thresh) 
        if type == 1
            effect_type(k) = 'inhibited';
        elseif type == 2
            effect_type(k) = 'disinhibited';
        end
    end
end

stats = table(pvals, (1:num_cells)', mean_scores, distrs, effect_type,...
    'VariableNames', {'pval', 'cell_idx', 'mean_scores', 'distr', 'effect'});

is_significant = stats.pval < p_thresh;
stats_sig = sortrows(stats(is_significant,:), 'pval');

% Cell inds
inhibited_inds = (stats_sig.effect == 'inhibited'); % Logical
inhibited_inds = table2array(stats_sig(inhibited_inds, 'cell_idx'))';
num_inhibited = length(inhibited_inds);

disinhibited_inds = (stats_sig.effect == 'disinhibited');
disinhibited_inds = table2array(stats_sig(disinhibited_inds, 'cell_idx'))';
num_disinhibited = length(disinhibited_inds);

other_inds = setdiff(1:num_cells, [inhibited_inds, disinhibited_inds]);
fprintf('%s: %d inhibited and %d disinhibited (%s, %s, p=%.4f)\n',...
    datestr(now), num_inhibited, num_disinhibited, laser_on_type, score_type, p_thresh);

% Prepare output
%------------------------------------------------------------
info.settings.laser_on_type = laser_on_type;
info.settings.laser_on_trials = laser_on_trials;
info.settings.laser_off_trials = laser_off_trials;
info.settings.score_type = score_type;
info.settings.p_thresh = p_thresh;
info.settings.num_shuffles = shuffle_info.shuffle_distr.num_shuffles;

info.results.inds.inhibited = inhibited_inds;
info.results.inds.disinhibited = disinhibited_inds;
info.results.inds.other = other_inds;
info.results.num_inhibited = num_inhibited;
info.results.num_disinhibited = num_disinhibited;
info.results.num_cells = num_cells;
info.results.full_stats = stats;
