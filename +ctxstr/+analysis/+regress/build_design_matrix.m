function X = build_design_matrix(model, trial_inds)
    num_regressors = length(model);

    Xs = cell(num_regressors+1, 1); % Extra term for DC offset
    for k = 1:num_regressors
        r = model{k};
        Xs{k} = ctxstr.core.concatenate_trials(r.X_by_trial, trial_inds);
    end
    Xs{end} = ones(1,size(Xs{1},2)); % DC offset
    X = cell2mat(Xs)'; % [num_frames x num_regressor_dofs]
end