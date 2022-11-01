function X = build_design_matrix(m, trial_inds)
    Xs = cell(m.num_regressors+1, 1); % Extra term for DC offset
    for k = 1:m.num_regressors
        r = m.regressors{k};
        Xs{k} = ctxstr.core.concatenate_trials(r.X_by_trial, trial_inds);
    end
    X = cell2mat(Xs)'; % [num_frames x num_regressor_dofs]
end