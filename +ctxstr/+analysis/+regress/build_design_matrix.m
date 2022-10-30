function X = build_design_matrix(m, trial_inds)
    Xs = cell(m.num_regressors+1, 1); % Extra term for DC offset
    for k = 1:m.num_regressors
        r = m.regressors{k};
        Xs{k} = ctxstr.core.concatenate_trials(r.X_by_trial, trial_inds);
    end
    Xs{end} = ones(1,size(Xs{1},2)); % DC offset
    X = cell2mat(Xs)'; % [num_frames x num_regressor_dofs]
end