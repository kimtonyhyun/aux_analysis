function visualize_opto_traces(ds, info, display_type)
% 'type' is either 'inhibited' or 'disinhibited'

switch display_type
    case {'inh', 'inhibited'}
        display_inds = info.results.inds.inhibited;
    case {'dis', 'disinhibited'}
        display_inds = info.results.inds.disinhibited;
end

plot_opto_cell(ds, display_inds,...
    info.opto.frame_inds.off, info.opto.frame_inds.on);

num_displayed = length(display_inds);
num_total_cells = info.results.num_cells;
title_str = sprintf('%s: %s (%s; %d of %d; %.1f%%)',...
    info.dataset_name,...
    display_type,...
    info.settings.score_type,...
    num_displayed, num_total_cells,...
    100*num_displayed/num_total_cells);
title(title_str);