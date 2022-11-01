function [results, fit_data] = fit_all_neurons(binned_traces_by_trial, st_trial_inds, models, active_frac_thresh, alpha, num_splits)

num_neurons = size(binned_traces_by_trial{1}, 1);
num_models = length(models);

fit_data = cell(num_neurons, num_models, num_splits);

results.active_fracs = zeros(num_neurons, 1);  % Fraction of trials with activity
results.fit_performed = false(num_neurons, 1); % Indicate whether fit was performed for this cell
results.R2 = zeros(num_neurons, num_models);
results.error = zeros(num_neurons, num_models);

for k = 1:num_neurons
    cprintf('blue', 'Cell=%d out of %d (%s)\n', k, num_neurons, datestr(now));
    
    binned_traces_by_trial_k = ctxstr.core.get_traces_for_cell(binned_traces_by_trial, k);
    [~, active_frac] = ctxstr.analysis.count_active_trials(binned_traces_by_trial_k, st_trial_inds);
    results.active_fracs(k) = active_frac;
    
    if active_frac < active_frac_thresh
        cprintf('red', '- Activity in only %.1f%% of ST trials. Skip fit!\n', 100*active_frac);
    else
        fprintf('- Activity on %.1f%% of ST trials\n', 100*active_frac);
        results.fit_performed(k) = true;
        tic;
        for m = 1:num_models
            model = models{m};
            
            R2_vals = zeros(num_splits, 1);
            for s = 1:num_splits
                [train_trial_inds, test_trial_inds] = ctxstr.analysis.regress.generate_train_test_trials(st_trial_inds, s);
                
                [kernels, biases, train_results, test_results] = ctxstr.analysis.regress.fit_neuron(...
                    binned_traces_by_trial_k, model,...
                    train_trial_inds, test_trial_inds, alpha, []);
                
                R2_vals(s) = test_results.R2(test_results.best_fit_ind);
                
                % Save full fit data for later inspection. All information
                % needed to run 'visualize_fit' needs to be saved.
                %--------------------------------------------------
                fd.train_trial_inds = train_trial_inds;
                fd.test_trial_inds = test_trial_inds;
                
                fd.kernels = kernels;
                fd.biases = biases;
                fd.train_results = train_results;
                fd.test_results = test_results;
                
                fit_data{k,m,s} = fd;
            end
            
            % Summarize results over splits
            results.R2(k,m) = mean(R2_vals);
            results.error(k,m) = std(R2_vals)/sqrt(num_splits);
            
            fprintf('- Model=%d (%s): R^2=%.3f+/-%.3f across %d train/test splits\n',...
                m, model.get_desc,...
                results.R2(k,m),...
                results.error(k,m),...
                num_splits);
        end
        t_run = toc;
        fprintf('- Took %.1f s to fit %d models\n', t_run, num_models);
    end
end
