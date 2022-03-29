function st_trial_ids = find_stereotypical_trials(trials)
% A trial is "stereotypical" if it meets the following criteria:
%   1) Reward-delivery-timed licking at the BEGINNING of the trial;
%   2) Reward-delivery-timed licking at the END of the trial;
%   3) At least one motion onset

num_all_trials = length(trials);
st_trial_ids = zeros(1, num_all_trials); % Preallocate

idx = 0;
for k = 2:num_all_trials
    trial = trials(k);
    prev_trial = trials(k-1);
    
    if prev_trial.lick_response && trial.lick_response && ~isempty(trial.motion.onsets)
        idx = idx + 1;
        st_trial_ids(idx) = k;
    end
end

st_trial_ids = st_trial_ids(1:idx);
