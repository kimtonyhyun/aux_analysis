function [traces, tdt] = load_cascade_traces(path_to_imdata, fps)

data = load(get_most_recent_file(path_to_imdata, 'cascade_*.mat'), 'spike_probs');
class = load_cell_class(path_to_imdata);
num_all_sources = length(class);

traces = fps * data.spike_probs';  % Convert to spike rates (Hz); [Cells x Time]
traces = traces(class,:); % Return only sources classified to be cells

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

end

function class = load_cell_class(path_to_class)

fid = fopen(get_most_recent_file(path_to_class, 'class_*.txt'), 'r');
class = textscan(fid, '%d %s', 'Delimiter', ',');
fclose(fid);

class = cellfun(@(x) strcmp(x, 'cell'), class{2}, 'UniformOutput', true);

end