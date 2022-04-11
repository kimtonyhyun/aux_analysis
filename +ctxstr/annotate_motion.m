function motion = annotate_motion(trials, Mb)

num_trials = length(trials);

% For each movement type (e.g. motion onsets), the entry for the k-th trial
% is a list of times (s; relative to Saleae record) where the movement was
% observed. Each trial may have multiple times where a specific movement
% type was observed (e.g. multiple movement onsets if the mouse came to
% rest before completing the trial). In the future, may add more movement
% types beyond motion onsets.
%------------------------------------------------------------
onsets = cell(num_trials, 1);

h = figure;

k = 1; % Trial index
ctxstr.show_trial(trials(k), Mb, h);

while (k <= num_trials)   

    % Prompt for user interaction
    prompt = sprintf('motion analyzer (%d/%d) >> ', ...
                        k, num_trials);
    resp = strtrim(input(prompt, 's'));
    
    val = str2double(resp);
    if (~isnan(val)) % Is a number. Check if it is a valid index and jump to it
        if ((1 <= val) && (val <= num_trials))
            k = val;
            ctxstr.show_trial(trials(k), Mb, h);
        else
            fprintf('  Sorry, %d is not a valid trial index\n', val);
        end
    else

        resp = lower(resp);
        switch (resp)
            % Label movements
            %------------------------------------------------------------
            case 'c'
                t0 = h.UserData.t0; % Selected time
                onsets{k} = [onsets{k} t0];
                fprintf('  Motion onset at t=%.3f s\n', t0);
            
            % Application options
            %------------------------------------------------------------                
            case ''
                if k < num_trials
                    k = k + 1;
                    ctxstr.show_trial(trials(k), Mb, h);
                else
                    cprintf('blue', 'Analyzed all trials!\n');
                end

            case 'q' % Exit
                % Save results
                
                close(h);
                break;
                
            otherwise
                fprintf('  Could not parse "%s"\n', resp);
                
        end
    end
end

% Save data
%------------------------------------------------------------
timestamp = datestr(now, 'yymmdd-HHMMSS');
output_name = sprintf('motion_%s.mat', timestamp);
save(output_name, 'onsets');

motion.onsets = onsets;

    % Auxiliary functions
    %------------------------------------------------------------
    
%     function go_to_next_unlabeled_cell()
%         unlabeled = cellfun(@isempty, ds.get_class);
%         next_idx = find_next_cell_to_process(trial_idx, unlabeled);
%         
%         if isempty(next_idx)
%             cprintf([0 0.5 0], '  All cells have been classified!\n');
%             prev_trial_index = trial_idx;
%             trial_idx = trial_idx + 1;
%             if trial_idx > ds.num_cells
%                 trial_idx = 1;
%             end
%         else
%             prev_trial_index = trial_idx;
%             trial_idx = next_idx;
%         end
%     end
        
end
