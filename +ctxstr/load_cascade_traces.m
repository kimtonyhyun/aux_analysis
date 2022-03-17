function [traces, tdt] = load_cascade_traces(path_to_imdata, fps)

data = load(get_most_recent_file(path_to_imdata, 'cascade_*.mat'), 'spike_probs');
class = load_cell_class(path_to_imdata);

traces = fps * data.spike_probs';  % Convert to spike rates (Hz); [Cells x Time]
traces = traces(class,:); % Return only sources classified to be cells

tdt = load_tdt(path_to_imdata); % FIXME: Filtering by class changes cell indices

end

function class = load_cell_class(path_to_class)

fid = fopen(get_most_recent_file(path_to_class, 'class_*.txt'), 'r');
class = textscan(fid, '%d %s', 'Delimiter', ',');
fclose(fid);

class = cellfun(@(x) strcmp(x, 'cell'), class{2}, 'UniformOutput', true);

end