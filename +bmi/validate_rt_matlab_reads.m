function [m, mismatch_table] = validate_rt_matlab_reads(s, matlab_results_file)
% Validate whether the RT predictions were read in by Matlab correctly:
%   - Check whether there are correct number of Matlab reads in the Saleae
%       BMI log and the Results file
%   - Check whether the Matlab read values in the Results file are as
%       expected given the Saleae BMI log
%
% Output:
%   - mismatch_table: Each row indicates a mismatched Matlab read value
%       [trial_idx, MR_idx_in_trial, MR_idx_in_saleae, matlab_val, saleae_val]
%

if ~exist('matlab_results_file', 'var')
    matlab_results_file = get_most_recent_file('.', 'Results_*.mat');
    fprintf('Using "%s"...\n', matlab_results_file);
end

% Parse data from Matlab side
%------------------------------------------------------------
rdata = load(matlab_results_file);
results = rdata.results;

% Find actual number of trials (i.e. with nonempty trial result)
num_trials = length([results.x0]);

m.matlab_vals_by_trial = cell(num_trials, 1);
m.num_matlab_reads_by_trial = zeros(num_trials, 1);
for k = 1:num_trials
    mr_k = results(k).BMI_counts_integ;

    m.matlab_vals_by_trial{k} = mr_k;
    m.num_matlab_reads_by_trial(k) = length(mr_k);
end

m.num_matlab_reads = sum(m.num_matlab_reads_by_trial);

if s.num_matlab_reads == m.num_matlab_reads
    cprintf('blue', '  Number of Matlab reads in Saleae matches that of Results.mat (%d Matlab reads)\n',...
        m.num_matlab_reads);
elseif s.num_matlab_reads > m.num_matlab_reads
    cprintf('red', '  Warning: Number of Matlab reads in Saleae (%d) EXCEEDS that of Results.mat (%d)!\n',...
        s.num_matlab_reads, m.num_matlab_reads);
else
    cprintf('red', '  Error: Number of Matlab reads in Saleae (%d) is FEWER than that of Results.mat (%d)!\n',...
        s.num_matlab_reads, m.num_matlab_reads);
end

% Validate Matlab read values
%------------------------------------------------------------
idx = 0;

% Format: [trial_idx, MR_idx_in_trial, MR_idx_in_saleae, matlab_val, saleae_val]
mismatch_table = zeros(m.num_matlab_reads, 5); 

num_mismatches = 0;
for k = 1:num_trials
    for j = 1:m.num_matlab_reads_by_trial(k)
        idx = idx + 1;

        matlab_val = m.matlab_vals_by_trial{k}(j);
        saleae_val = s.matlab_read_vals(idx);

        % Don't check the first value in a trial (j=1) since Saleae isn't
        % expected to track this value properly
        if (j ~= 1) && (matlab_val ~= saleae_val)
            num_mismatches = num_mismatches + 1;
            mismatch_table(num_mismatches,:) = [k, j, idx, matlab_val, saleae_val];

            cprintf('red', '  Trial %d, Matlab read idx %d/%d: Saleae says Matlab read value should be %d, but found %d in Results file\n',...
                k, j, m.num_matlab_reads_by_trial(k), saleae_val, matlab_val);
            
        end
    end
end
mismatch_table = mismatch_table(1:idx,:);

if num_mismatches > 0
    cprintf('red',  'Found %d unexpected Matlab read values out of %d total (%.1f%%)\n',...
        num_mismatches, m.num_matlab_reads, num_mismatches/m.num_matlab_reads * 100.0);
end