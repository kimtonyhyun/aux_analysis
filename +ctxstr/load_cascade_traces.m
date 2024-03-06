function [traces, info] = load_cascade_traces(path_to_imdata, fps, varargin)
% Note: 'traces' only contains cells that have been classified to be true
% cells in the associated classification file.

normalize_traces = true; % TODO: Allow for disabling via varargin
load_traces_from_rec = false;

for k = 1:length(varargin)
    if ischar(varargin{k})
        switch lower(varargin{k})
            case 'rec' % Load the fluorescence traces instead of CASCADE
                load_traces_from_rec = true;
        end
    end
end

class = load_cell_class(path_to_imdata);
num_all_sources = length(class);

if ~load_traces_from_rec
    data = load(get_most_recent_file(path_to_imdata, 'cascade_*.mat'), 'spike_probs');

    traces = fps * data.spike_probs';  % Convert to spike rates (Hz); [Cells x Time]
    traces = traces(class,:); % Return only sources classified to be cells
else
    cprintf('blue', 'load_cascade_traces: Loaded fluorescence traces from rec file instead!\n');
    data = load(get_most_recent_file(path_to_imdata, 'rec_*.mat'), 'traces');
    traces = data.traces';
    traces = traces(class,:);
end

if normalize_traces
    for k = 1:size(traces,1)
        tr = traces(k,:);
        % Note: For CASCADE traces, minimum trace value can be reasonably
        % assumed to be 0, hence normalization by just the max value. On
        % the other hand, other types of traces, such as fluorescence
        % traces, should probably subtract off the min value as well.
        
        tr_max = max(tr);
        if (tr_max > 0)
            traces(k,:) = tr / tr_max;
        else
            % We have seen cases where the CASCADE output is strictly zero,
            % which causes division by 0 during normalization
            cprintf('blue', '  Warning: Trace %d has unusual max(tr) = %.3f! Did not normalize trace\n', k, tr_max);
        end
    end
end

tdt = load_tdt(path_to_imdata);
if ~isempty(tdt)
    % Below: Make cell indices consistent with 'traces', given that the latter
    % only keeps sources that are classified to be cells
    tdt_pos_cells = zeros(1, num_all_sources);
    tdt_pos_cells(tdt.pos) = 1;
    tdt_pos_cells = tdt_pos_cells(class);
    tdt.pos = find(tdt_pos_cells);

    tdt_neg_cells = zeros(1, num_all_sources);
    tdt_neg_cells(tdt.neg) = 1;
    tdt_neg_cells = tdt_neg_cells(class);
    tdt.neg = find(tdt_neg_cells);
end

[~, info.rec_name] = fileparts(get_most_recent_file(path_to_imdata, 'rec_*.mat'));
info.num_cells = size(traces,1);
info.tdt = tdt;

% This function returns only traces belonging to sources classified to be
% cells, whereas the DaySummary may contain a mixture of true and rejected
% cells. Thus, the following conversion functions are necessary to relate
% cell indices in 'traces' and the original DaySummary.
info.ind2rec = find(class); % Index in 'traces' to Rec index
rec2ind = zeros(size(class));
ind = 0;
for k = 1:length(rec2ind)
    if class(k)
        ind = ind + 1;
        rec2ind(k) = ind;
    end
end
info.rec2ind = rec2ind; % Rec index to Index in 'traces'

end

function class = load_cell_class(path_to_class)

fid = fopen(get_most_recent_file(path_to_class, 'class_*.txt'), 'r');
class = textscan(fid, '%d %s', 'Delimiter', ',');
fclose(fid);

class = cellfun(@(x) strcmp(x, 'cell'), class{2}, 'UniformOutput', true);

end