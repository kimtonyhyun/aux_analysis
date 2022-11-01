function [train_trial_inds, test_trial_inds] = generate_train_test_trials(trial_inds, split_no)

switch split_no
    case {1,2,3}
        % Every third trial is a test trial
        test_trial_inds = trial_inds(split_no:3:end);
        
    otherwise
        % Randomly select ~1/3 of trials as test trials
        num_trials = length(trial_inds);
        num_test_trials = floor(num_trials/3);
        
        p = randperm(num_trials);
        test_trial_inds = sort(trial_inds(p(1:num_test_trials)));
end

train_trial_inds = setdiff(trial_inds, test_trial_inds);

% To save memory when storing the fit results across many splits
train_trial_inds = uint16(train_trial_inds);
test_trial_inds = uint16(test_trial_inds);