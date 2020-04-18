function [NLL, Q, p, info] = basic_Q_model(behavior_data, Q0, alpha, beta)
% Implement the basic Q update equations (Mansheej).
%
% Inputs:
%   behavior_data: [num_trials x 3] list of (state, action, reward).
%   Q0: Initial table of Q values
%   alpha: Learning rate in update equations.
%   beta: Inverse temperature for action emission.
%
% Encoding format:
%   Q, p: Organized as [State x Action x Trials]. Index is such that
%       Q(:,:,k) represents the Q value at the _start_ of k-th trial (i.e.
%       prior to that trial's result).
%   States: {1 (East), 2 (West)}
%   Actions: {1 (North), 2 (South)}

num_trials = size(behavior_data, 1);

Q = zeros(2, 2, 1+num_trials);
p = zeros(2, 2, 1+num_trials);

Q(:,:,1) = Q0; % Initialization
p(:,:,1) = compute_action_probabilities(Q0, beta);

NLL = 0;
for k = 1:num_trials
    % True behavioral data
    s = behavior_data(k,1);
    a = behavior_data(k,2);
    r = behavior_data(k,3);
    
    NLL = NLL - log(p(s,a,k));
    
    % Use behavioral data to update Q for next trial
    Q(:,:,k+1) = Q(:,:,k);
    Q(s,a,k+1) = Q(s,a,k) + alpha * (r - Q(s,a,k));
    
    p(:,:,k+1) = compute_action_probabilities(Q(:,:,k+1), beta);    
end

NLL = NLL/num_trials;
Q = Q(:,:,1:num_trials);
p = p(:,:,1:num_trials);

info.name = 'basic';
info.alpha = alpha;
info.beta = beta;

end % basic_Q_model

function p = compute_action_probabilities(Q, beta)
    % For one trial, compute the action probabilities from Q using the
    % Boltzmann distribution
    
    % Pr(a=1|s=1)
    p(1,1) = exp(beta*Q(1,1)) / (exp(beta*Q(1,1)) + exp(beta*Q(1,2)));
    
    % Pr(a=2|s=1)
    p(1,2) = 1 - p(1,1);
    
    % Pr(a=1|s=2)
    p(2,1) = exp(beta*Q(2,1)) / (exp(beta*Q(2,1)) + exp(beta*Q(2,2)));
    
    % Pr(a=2|s=2)
    p(2,2) = 1 - p(2,1);
end